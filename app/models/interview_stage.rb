class InterviewStage < ApplicationRecord
  belongs_to :job_application

  enum :stage_type, {
    phone_screen: 0,
    technical_screen: 1,
    onsite: 2,
    offer: 3
  }

  enum :outcome, {
    pending: 0,
    passed: 1,
    failed: 2
  }, default: :pending

  validates :stage_type, presence: true
end
