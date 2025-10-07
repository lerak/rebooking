# Service class to handle Twilio SMS operations
class TwilioService
  class TwilioError < StandardError; end

  def initialize
    @client = Twilio::REST::Client.new
  end

  # Send an SMS message
  # @param to [String] The recipient phone number in E.164 format (e.g., +1234567890)
  # @param body [String] The message body
  # @param from [String] Optional sender phone number, defaults to configured Twilio number
  # @return [Twilio::REST::Api::V2010::AccountContext::MessageInstance] The Twilio message object
  # @raise [TwilioError] If the message fails to send
  def send_sms(to:, body:, from: nil)
    from_number = from || TWILIO_PHONE_NUMBER

    raise TwilioError, "Twilio phone number not configured" if from_number.blank?
    raise TwilioError, "Recipient phone number is required" if to.blank?
    raise TwilioError, "Message body is required" if body.blank?

    message = @client.messages.create(
      to: to,
      from: from_number,
      body: body
    )

    message
  rescue Twilio::REST::RestError => e
    raise TwilioError, "Failed to send SMS: #{e.message}"
  end
end
