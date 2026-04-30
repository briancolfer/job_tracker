FactoryBot.define do
  factory :job_application do
    company { Faker::Company.name }
    role_title { Faker::Job.title }
    job_type { "DevOps" }
    location { Faker::Address.city }
    days_in_office { nil }
    source { "LinkedIn" }
    status { :applied }
    apply_date { Faker::Date.backward(days: 30) }
    job_posting_url { Faker::Internet.url }
    notes { nil }
  end
end
