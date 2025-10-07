# Service class to manage SMS consent for customers
class ConsentManager
  def initialize(customer)
    @customer = customer
  end

  # Record opt-in consent for a customer
  # @param consent_text [String] The consent text or message
  # @param metadata [Hash] Additional metadata to store with the consent log
  # @return [Boolean] true if successful, false otherwise
  def opt_in(consent_text: "Customer provided phone number and consented to SMS notifications", metadata: {})
    return false if @customer.opted_out?

    ActiveRecord::Base.transaction do
      @customer.update!(
        sms_consent_status: :active,
        opted_out_at: nil
      )

      @customer.consent_logs.create!(
        event_type: :opted_in,
        consent_text: consent_text,
        consented_at: Time.current,
        metadata: metadata
      )
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  # Record opt-out for a customer (e.g., when they reply STOP)
  # @param reason [String] The reason for opt-out (e.g., "Customer replied STOP")
  # @param metadata [Hash] Additional metadata to store with the consent log
  # @return [Boolean] true if successful, false otherwise
  def opt_out(reason: "Customer opted out", metadata: {})
    return false unless @customer.can_receive_sms?

    ActiveRecord::Base.transaction do
      @customer.update!(
        sms_consent_status: :opted_out,
        opted_out_at: Time.current
      )

      @customer.consent_logs.create!(
        event_type: :opted_out,
        consent_text: reason,
        consented_at: Time.current,
        metadata: metadata
      )
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end
end
