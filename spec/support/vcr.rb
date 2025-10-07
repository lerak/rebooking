require 'vcr'

VCR.configure do |config|
  # Configure VCR to use the spec/fixtures/vcr_cassettes directory for storing cassettes
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'

  # Use Webmock as the HTTP stubbing library
  config.hook_into :webmock

  # Allow VCR to be used with RSpec metadata
  # Tests tagged with :vcr will automatically use VCR
  config.configure_rspec_metadata!

  # Filter sensitive data from cassettes
  config.filter_sensitive_data('<TWILIO_ACCOUNT_SID>') do |interaction|
    # Extract account SID from request URI or body
    if interaction.request.uri.match?(/api\.twilio\.com/)
      interaction.request.uri.match(%r{/Accounts/([^/]+)/})[1] rescue nil
    end
  end

  config.filter_sensitive_data('<TWILIO_AUTH_TOKEN>') do |interaction|
    # Extract auth token from Authorization header
    if auth_header = interaction.request.headers['Authorization']&.first
      auth_header.split(':').last rescue nil
    end
  end

  config.filter_sensitive_data('<TWILIO_PHONE_NUMBER>') do
    Rails.application.credentials.dig(:twilio, :phone_number)
  end

  # Allow real HTTP connections to localhost for test server
  config.allow_http_connections_when_no_cassette = false

  # Ignore localhost requests (for Rails test server)
  config.ignore_localhost = true

  # Configure default cassette options
  config.default_cassette_options = {
    record: :once, # Record new interactions only once
    match_requests_on: [:method, :uri, :body]
  }
end
