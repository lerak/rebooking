FactoryBot.define do
  factory :customer do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    phone { Faker::PhoneNumber.cell_phone }
    sequence(:email) { |n| "customer#{n}@example.com" }
    association :business
  end
end
