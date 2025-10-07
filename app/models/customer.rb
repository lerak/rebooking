class Customer < ApplicationRecord
  acts_as_tenant :business
  belongs_to :business
  has_many :appointments, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :consent_logs, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phone, presence: true, uniqueness: { scope: :business_id }
end
