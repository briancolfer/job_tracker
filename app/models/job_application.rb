class JobApplication < ApplicationRecord
  enum :status,
    JobTracker::StatusCatalog.enum_mapping,
    default: JobTracker::StatusCatalog.default_code.to_sym,
    validate: true

  has_many :interview_stages, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :follow_ups, dependent: :destroy

  validates :company, presence: true
  validates :apply_date, presence: true
  validates :days_in_office, inclusion: { in: 0..5 }, allow_nil: true

  def remote?
    days_in_office == 0
  end

  def hybrid?
    days_in_office.present? && (1..4).cover?(days_in_office)
  end

  def onsite?
    days_in_office == 5
  end

  def arrangement_label
    case days_in_office
    when 0     then "Remote"
    when 1..4  then "Hybrid (#{days_in_office} days/week)"
    when 5     then "On-site (5 days/week)"
    else            "Unknown"
    end
  end

  def status_label
    JobTracker::StatusCatalog.label(status)
  end

  scope :active, -> { where.not(status: JobTracker::StatusCatalog.terminal_codes & statuses.keys) }
  scope :terminal, -> { where(status: JobTracker::StatusCatalog.terminal_codes & statuses.keys) }
  scope :applied_after, ->(date) { where("apply_date >= ?", date) }
  scope :applied_before, ->(date) { where("apply_date <= ?", date) }
end
