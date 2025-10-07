class Business < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :messages, dependent: :destroy

  validates :name, presence: true
  validates :timezone, presence: true
  validates :reminder_hours_before, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
end
