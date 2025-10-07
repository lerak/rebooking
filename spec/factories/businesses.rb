FactoryBot.define do
  factory :business do
    name { Faker::Company.name }
    timezone { "America/New_York" }
  end
end
