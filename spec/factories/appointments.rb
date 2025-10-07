FactoryBot.define do
  factory :appointment do
    association :customer
    association :business
    start_time { 2.days.from_now.change(hour: 10, min: 0) }
    end_time { start_time + 1.hour }
    status { :scheduled }
  end
end
