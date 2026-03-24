FactoryBot.define do
  factory :follow_up do
    association :job_application
    due_date { 1.week.from_now }
    description { "Follow up on application" }
    completed { false }
  end
end
