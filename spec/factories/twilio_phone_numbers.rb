FactoryBot.define do
  factory :twilio_phone_number do
    business
    sequence(:phone_number) { |n| "+1555555#{1000 + n}" }
    status { :pending }
    location { "Main Office" }

    trait :pending do
      status { :pending }
    end

    trait :approved do
      status { :approved }
    end

    trait :active do
      status { :active }
    end
  end
end
