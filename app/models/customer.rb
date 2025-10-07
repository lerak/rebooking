class Customer < ApplicationRecord
  acts_as_tenant :business
  belongs_to :business
  has_many :appointments, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :consent_logs, dependent: :destroy

  enum :sms_consent_status, { pending: 0, active: 1, opted_out: 2 }, default: :active

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phone, presence: true, uniqueness: { scope: :business_id }

  after_create :create_initial_consent_log

  # Check if customer has active SMS consent
  def consented?
    active?
  end

  # Check if customer has opted out
  def opted_out?
    sms_consent_status == "opted_out"
  end

  # Check if customer can receive SMS messages
  def can_receive_sms?
    consented? && !opted_out?
  end

  private

  def create_initial_consent_log
    return unless phone.present?

    consent_logs.create!(
      event_type: :opted_in,
      consent_text: "Customer provided phone number and consented to SMS notifications",
      consented_at: Time.current
    )
  end
end
