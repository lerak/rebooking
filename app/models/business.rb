class Business < ApplicationRecord
  has_many :users, dependent: :destroy
  # has_many :customers, dependent: :destroy  # Will be added in task 3.0
  # has_many :appointments, dependent: :destroy  # Will be added in task 3.0
  # has_many :messages, dependent: :destroy  # Will be added in task 3.0

  validates :name, presence: true
  validates :timezone, presence: true
end
