FactoryBot.define do
  factory :interview_stage do
    association :job_application
    stage_type { :phone_screen }
    scheduled_at { 1.week.from_now }
    completed_at { nil }
    outcome { :pending }
    notes { nil }
  end
end
