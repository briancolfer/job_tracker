class JobStatus < ApplicationRecord
  class ValidationError < StandardError; end

  CODE_PATTERN = /\A[a-z][a-z0-9_]*\z/

  scope :ordered, -> { order(:value) }
  scope :terminal, -> { where(terminal: true) }

  validates :code,
    presence: true,
    uniqueness: true,
    format: { with: CODE_PATTERN, message: "must use lowercase snake_case" }
  validates :value,
    presence: true,
    uniqueness: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :label, presence: true
  validates :default, uniqueness: true, if: :default?

  class << self
    def definitions
      ordered.each_with_object({}) do |status, result|
        result[status.code] = status.attributes.slice("value", "label", "terminal", "default")
      end
    end

    def definition(code)
      find_by(code: code.to_s)
    end

    def codes
      ordered.pluck(:code)
    end

    def enum_mapping
      ordered.pluck(:code, :value).to_h
    end

    def default_code
      find_by(default: true)&.code || raise(ValidationError, "Job statuses must define one default status")
    end

    def terminal_codes
      terminal.order(:value).pluck(:code)
    end

    def label(code)
      definition(code)&.label || code.to_s.humanize
    end

    def options
      ordered.pluck(:label, :code)
    end

    def add(code, label:, terminal: false)
      status_code = code.to_s
      raise ValidationError, "Status '#{status_code}' already exists" if exists?(code: status_code)

      create!(
        code: status_code,
        value: maximum(:value).to_i + 1,
        label: label.to_s.strip,
        terminal: !!terminal
      )
    rescue ActiveRecord::RecordInvalid => e
      raise ValidationError, e.record.errors.full_messages.to_sentence
    end
  end

  def update_definition(new_code: nil, label: nil, terminal: nil)
    target_code = new_code.presence || code
    if new_code.nil? && label.nil? && terminal.nil?
      raise ValidationError, "Specify --new-code, --label, --terminal, or --no-terminal"
    end
    if target_code != code && self.class.exists?(code: target_code)
      raise ValidationError, "Status '#{target_code}' already exists"
    end

    update!(
      code: target_code,
      label: label.nil? ? self.label : label.to_s.strip,
      terminal: terminal.nil? ? self.terminal : terminal
    )
    self
  rescue ActiveRecord::RecordInvalid => e
    raise ValidationError, e.record.errors.full_messages.to_sentence
  end
end
