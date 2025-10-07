class Message < ApplicationRecord
  acts_as_tenant :business
  belongs_to :customer
  belongs_to :business

  enum :direction, { inbound: 0, outbound: 1 }
  enum :status, { received: 0, sent: 1, failed: 2, queued: 3, delivered: 4, undelivered: 5 }, default: :received

  validates :body, presence: true
  validates :direction, presence: true
end
