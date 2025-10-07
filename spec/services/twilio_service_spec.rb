require 'rails_helper'

RSpec.describe TwilioService, type: :service do
  let(:service) { described_class.new }
  let(:to_number) { '+15555551234' }
  let(:message_body) { 'Test message' }
  let(:from_number) { '+15555555678' }
  let(:twilio_client) { instance_double(Twilio::REST::Client) }
  let(:messages_list) { instance_double(Twilio::REST::Api::V2010::AccountContext::MessageList) }
  let(:message_instance) do
    instance_double(
      Twilio::REST::Api::V2010::AccountContext::MessageInstance,
      to: to_number,
      from: from_number,
      body: message_body,
      sid: 'SM123456789'
    )
  end

  before do
    # Stub the TWILIO_PHONE_NUMBER constant
    stub_const('TWILIO_PHONE_NUMBER', from_number)

    # Stub Twilio client initialization
    allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
    allow(twilio_client).to receive(:messages).and_return(messages_list)
  end

  describe '#send_sms' do
    context 'when sending a valid SMS' do
      it 'sends an SMS successfully' do
        allow(messages_list).to receive(:create).with(
          to: to_number,
          from: from_number,
          body: message_body
        ).and_return(message_instance)

        result = service.send_sms(to: to_number, body: message_body)

        expect(result).to eq(message_instance)
        expect(result.to).to eq(to_number)
        expect(result.body).to eq(message_body)
      end

      it 'uses the configured from number when not specified' do
        allow(messages_list).to receive(:create).with(
          to: to_number,
          from: from_number,
          body: message_body
        ).and_return(message_instance)

        result = service.send_sms(to: to_number, body: message_body)

        expect(result.from).to eq(from_number)
      end

      it 'uses a custom from number when specified' do
        custom_from = '+15555559999'
        custom_message = instance_double(
          Twilio::REST::Api::V2010::AccountContext::MessageInstance,
          to: to_number,
          from: custom_from,
          body: message_body
        )

        allow(messages_list).to receive(:create).with(
          to: to_number,
          from: custom_from,
          body: message_body
        ).and_return(custom_message)

        result = service.send_sms(to: to_number, body: message_body, from: custom_from)

        expect(result.from).to eq(custom_from)
      end
    end

    context 'when validation fails' do
      it 'raises an error when recipient number is blank' do
        expect {
          service.send_sms(to: '', body: message_body)
        }.to raise_error(TwilioService::TwilioError, 'Recipient phone number is required')
      end

      it 'raises an error when message body is blank' do
        expect {
          service.send_sms(to: to_number, body: '')
        }.to raise_error(TwilioService::TwilioError, 'Message body is required')
      end

      it 'raises an error when Twilio phone number is not configured' do
        stub_const('TWILIO_PHONE_NUMBER', nil)

        expect {
          service.send_sms(to: to_number, body: message_body)
        }.to raise_error(TwilioService::TwilioError, 'Twilio phone number not configured')
      end
    end

    context 'when Twilio API fails' do
      it 'raises a TwilioError with the API error message' do
        error = Twilio::REST::RestError.allocate
        allow(error).to receive(:message).and_return('Invalid phone number')

        allow(messages_list).to receive(:create).and_raise(error)

        expect {
          service.send_sms(to: to_number, body: message_body)
        }.to raise_error(TwilioService::TwilioError, /Failed to send SMS/)
      end
    end
  end
end
