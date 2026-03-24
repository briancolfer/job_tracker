FactoryBot.define do
  factory :contact do
    association :job_application
    name { Faker::Name.name }
    role { :recruiter }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.phone_number }
    linkedin_url { Faker::Internet.url(host: 'linkedin.com') }
    notes { nil }
  end
end
