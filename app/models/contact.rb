class Contact < ApplicationRecord
  belongs_to :job_application

  enum :role, {
    recruiter: 0,
    hiring_manager: 1,
    interviewer: 2,
    other: 3
  }, default: :recruiter

  validates :name, presence: true
end
