class JobApplication < ApplicationRecord
  TERMINAL_STATUSES = %w[rejected withdrawn ghosted].freeze

  enum :status, {
    cold_call: 0,
    applied: 1,
    phone_screen: 2,
    technical_screen: 3,
    onsite: 4,
    offer_received: 5,
    accepted: 6,
    rejected: 7,
    withdrawn: 8,
    ghosted: 9
  }, default: :applied, validate: true

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

  scope :active, -> { where.not(status: TERMINAL_STATUSES.map { |s| statuses[s] }) }
  scope :terminal, -> { where(status: TERMINAL_STATUSES.map { |s| statuses[s] }) }
  scope :applied_after, ->(date) { where("apply_date >= ?", date) }
  scope :applied_before, ->(date) { where("apply_date <= ?", date) }
end
