class FollowUp < ApplicationRecord
  belongs_to :job_application

  validates :due_date, presence: true
  validates :description, presence: true

  scope :pending, -> { where(completed: false) }
  scope :overdue, -> { pending.where('due_date < ?', Date.today) }
  scope :due_today, -> { pending.where(due_date: Date.today) }
end
