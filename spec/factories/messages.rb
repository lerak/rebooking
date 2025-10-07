FactoryBot.define do
  factory :message do
    association :customer
    association :business
    body { Faker::Lorem.sentence }
    direction { :outbound }
    status { :sent }
    metadata { {} }
  end
end
