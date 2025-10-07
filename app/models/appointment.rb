class Appointment < ApplicationRecord
  acts_as_tenant :business
  belongs_to :customer
  belongs_to :business

  enum :status, { scheduled: 0, confirmed: 1, completed: 2, cancelled: 3 }, default: :scheduled

  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_time_after_start_time

  private

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    if end_time < start_time
      errors.add(:end_time, "must be after start time")
    end
  end
end
