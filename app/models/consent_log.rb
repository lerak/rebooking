class ConsentLog < ApplicationRecord
  belongs_to :customer

  validates :consent_text, presence: true
  validates :consented_at, presence: true
end
