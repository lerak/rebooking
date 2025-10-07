class TwilioPhoneNumber < ApplicationRecord
  belongs_to :business

  enum :status, { pending: 0, approved: 1, active: 2 }, default: :pending

  validates :phone_number, presence: true, uniqueness: true
  validates :status, presence: true
  validates :location, presence: true

  # Admin approval helper methods
  def approve!
    update!(status: :approved)
  end

  def activate!
    update!(status: :active)
  end

  def reject!
    destroy
  end
end
