FactoryBot.define do
  factory :consent_log do
    association :customer
    consent_text { "I consent to receive text messages from this business." }
    consented_at { Time.current }
  end
end
