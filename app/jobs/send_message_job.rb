class SendMessageJob < ApplicationJob
  queue_as :default

  def perform(customer_id, message_body, business_id)
    customer = Customer.find(customer_id)
    business = Business.find(business_id)

    # Check if customer has consented to receive SMS
    unless customer.can_receive_sms?
      Rails.logger.info "Skipping SMS for customer #{customer.id} - no consent"
      return
    end

    # Use business's Twilio phone number or fall back to global config
    from_number = business.twilio_phone_number || TWILIO_PHONE_NUMBER

    # Send SMS via Twilio
    twilio_service = TwilioService.new
    message = twilio_service.send_sms(
      to: customer.phone,
      body: message_body,
      from: from_number
    )

    # Create message record
    Message.create!(
      customer: customer,
      business: business,
      body: message_body,
      direction: :outbound,
      status: :sent,
      twilio_sid: message.sid
    )
  rescue TwilioService::TwilioError => e
    Rails.logger.error "Failed to send SMS to customer #{customer_id}: #{e.message}"

    # Create failed message record
    Message.create!(
      customer: customer,
      business: business,
      body: message_body,
      direction: :outbound,
      status: :failed,
      error_message: e.message
    )
  end
end
