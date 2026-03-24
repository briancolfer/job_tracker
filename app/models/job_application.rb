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
  }, default: :applied

  has_many :interview_stages, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :follow_ups, dependent: :destroy

  validates :company, presence: true
  validates :apply_date, presence: true

  scope :active, -> { where.not(status: TERMINAL_STATUSES.map { |s| statuses[s] }) }
  scope :terminal, -> { where(status: TERMINAL_STATUSES.map { |s| statuses[s] }) }
end
