require 'rails_helper'

RSpec.describe SendMessageJob, type: :job do
  let(:business) { create(:business, twilio_phone_number: '+1234567890') }
  let(:customer) { create(:customer, phone: '+19876543210', business: business, sms_consent_status: :active) }
  let(:message_body) { 'Test message' }
  let(:twilio_service) { instance_double(TwilioService) }
  let(:twilio_message) { double('Twilio::Message', sid: 'SM123456') }

  before do
    allow(TwilioService).to receive(:new).and_return(twilio_service)
  end

  describe '#perform' do
    context 'when customer has consented' do
      it 'sends SMS via TwilioService' do
        expect(twilio_service).to receive(:send_sms).with(
          to: customer.phone,
          body: message_body,
          from: business.twilio_phone_number
        ).and_return(twilio_message)

        described_class.perform_now(customer.id, message_body, business.id)
      end

      it 'creates a message record with sent status' do
        allow(twilio_service).to receive(:send_sms).and_return(twilio_message)

        expect {
          described_class.perform_now(customer.id, message_body, business.id)
        }.to change { Message.count }.by(1)

        message = Message.last
        expect(message.customer).to eq(customer)
        expect(message.business).to eq(business)
        expect(message.body).to eq(message_body)
        expect(message.direction).to eq('outbound')
        expect(message.status).to eq('sent')
        expect(message.twilio_sid).to eq('SM123456')
      end

      it 'uses global TWILIO_PHONE_NUMBER when business has no phone number' do
        business.update!(twilio_phone_number: nil)

        expect(twilio_service).to receive(:send_sms).with(
          to: customer.phone,
          body: message_body,
          from: TWILIO_PHONE_NUMBER
        ).and_return(twilio_message)

        described_class.perform_now(customer.id, message_body, business.id)
      end
    end

    context 'when customer has not consented' do
      before do
        customer.update!(sms_consent_status: :opted_out)
      end

      it 'does not send SMS' do
        expect(twilio_service).not_to receive(:send_sms)

        described_class.perform_now(customer.id, message_body, business.id)
      end

      it 'does not create a message record' do
        expect {
          described_class.perform_now(customer.id, message_body, business.id)
        }.not_to change { Message.count }
      end

      it 'logs the skip' do
        allow(Rails.logger).to receive(:info)

        described_class.perform_now(customer.id, message_body, business.id)

        expect(Rails.logger).to have_received(:info).with(/Skipping SMS for customer/)
      end
    end

    context 'when customer status is pending' do
      before do
        customer.update!(sms_consent_status: :pending)
      end

      it 'does not send SMS' do
        expect(twilio_service).not_to receive(:send_sms)

        described_class.perform_now(customer.id, message_body, business.id)
      end
    end

    context 'when Twilio API fails' do
      before do
        allow(twilio_service).to receive(:send_sms).and_raise(
          TwilioService::TwilioError.new('API Error')
        )
      end

      it 'creates a message record with failed status' do
        expect {
          described_class.perform_now(customer.id, message_body, business.id)
        }.to change { Message.count }.by(1)

        message = Message.last
        expect(message.status).to eq('failed')
        expect(message.error_message).to eq('API Error')
        expect(message.twilio_sid).to be_nil
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)

        described_class.perform_now(customer.id, message_body, business.id)

        expect(Rails.logger).to have_received(:error).with(/Failed to send SMS/)
      end
    end
  end
end
