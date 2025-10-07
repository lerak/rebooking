# Twilio SMS Integration Configuration
# Credentials are stored in Rails encrypted credentials

require 'twilio-ruby'

Twilio.configure do |config|
  config.account_sid = Rails.application.credentials.dig(:twilio, :account_sid)
  config.auth_token = Rails.application.credentials.dig(:twilio, :auth_token)
end

# Store the phone number for easy access
TWILIO_PHONE_NUMBER = Rails.application.credentials.dig(:twilio, :phone_number)
