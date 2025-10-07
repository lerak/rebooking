class ConsentLog < ApplicationRecord
  belongs_to :customer

  enum :event_type, { opted_in: 0, opted_out: 1 }, default: :opted_in

  validates :consent_text, presence: true
  validates :consented_at, presence: true
  validates :event_type, presence: true
end
