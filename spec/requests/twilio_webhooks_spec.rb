require 'rails_helper'

RSpec.describe "TwilioWebhooks", type: :request do
  let(:business) { create(:business, name: "Test Clinic") }
  let(:customer) { create(:customer, business: business, phone: "+19876543210", sms_consent_status: :active) }
  let(:auth_token) { "test_auth_token" }

  before do
    # Stub credentials
    allow(Rails.application.credentials).to receive(:dig).with(:twilio, :auth_token).and_return(auth_token)
  end

  describe "POST /webhooks/twilio/inbound" do
    let(:twilio_params) {
      {
        'From' => customer.phone,
        'Body' => 'Test message',
        'MessageSid' => 'SM123456789'
      }
    }

    context "with valid Twilio signature" do
      before do
        # Mock Twilio signature validation
        validator = instance_double(Twilio::Security::RequestValidator)
        allow(Twilio::Security::RequestValidator).to receive(:new).with(auth_token).and_return(validator)
        allow(validator).to receive(:validate).and_return(true)

        # Stub Turbo Stream broadcast to avoid missing partial error
        allow_any_instance_of(Message).to receive(:broadcast_append_to)
      end

      it "creates a new inbound message" do
        expect {
          post webhooks_twilio_inbound_path, params: twilio_params, headers: { 'X-Twilio-Signature' => 'valid_signature' }
        }.to change { Message.count }.by(1)

        message = Message.last
        expect(message.customer).to eq(customer)
        expect(message.business).to eq(business)
        expect(message.direction).to eq('inbound')
        expect(message.status).to eq('received')
        expect(message.body).to eq('Test message')
        expect(message.twilio_sid).to eq('SM123456789')
      end

      it "returns OK response" do
        post webhooks_twilio_inbound_path, params: twilio_params, headers: { 'X-Twilio-Signature' => 'valid_signature' }
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('OK')
      end

      it "handles unknown customer gracefully" do
        twilio_params['From'] = '+15555555555'

        expect {
          post webhooks_twilio_inbound_path, params: twilio_params, headers: { 'X-Twilio-Signature' => 'valid_signature' }
        }.not_to change { Message.count }

        expect(response).to have_http_status(:ok)
      end

      context "when message contains STOP keyword" do
        before do
          twilio_params['Body'] = 'STOP'
        end

        it "opts out the customer" do
          expect {
            post webhooks_twilio_inbound_path, params: twilio_params, headers: { 'X-Twilio-Signature' => 'valid_signature' }
          }.to change { customer.reload.sms_consent_status }.from('active').to('opted_out')
        end

        it "creates a consent log entry" do
          expect {
            post webhooks_twilio_inbound_path, params: twilio_params, headers: { 'X-Twilio-Signature' => 'valid_signature' }
          }.to change { ConsentLog.where(customer: customer, event_type: 'opted_out').count }.by(1)
        end

        it "returns OK without broadcasting" do
          post webhooks_twilio_inbound_path, params: twilio_params, headers: { 'X-Twilio-Signature' => 'valid_signature' }
          expect(response).to have_http_status(:ok)
        end
      end

      context "when message contains HELP keyword" do
        before do
          twilio_params['Body'] = 'HELP'
        end

        it "queues auto-reply message" do
          expect {
            post webhooks_twilio_inbound_path, params: twilio_params, headers: { 'X-Twilio-Signature' => 'valid_signature' }
          }.to have_enqueued_job(SendMessageJob).with(customer.id, /Reply STOP to unsubscribe/, business.id)
        end

        it "includes business name in help message" do
          post webhooks_twilio_inbound_path, params: twilio_params, headers: { 'X-Twilio-Signature' => 'valid_signature' }
          expect(SendMessageJob).to have_been_enqueued.with(customer.id, /Test Clinic/, business.id)
        end
      end

      context "Turbo Stream broadcasting" do
        it "calls broadcast_append_to on created message" do
          # Verify broadcast method is called (actual broadcasting tested in system specs)
          expect_any_instance_of(Message).to receive(:broadcast_append_to).with(
            "business_#{business.id}_messages",
            hash_including(target: "messages", partial: "messages/message")
          )

          post webhooks_twilio_inbound_path, params: twilio_params, headers: { 'X-Twilio-Signature' => 'valid_signature' }
        end
      end
    end

    context "with invalid Twilio signature" do
      before do
        # Mock invalid signature validation
        validator = instance_double(Twilio::Security::RequestValidator)
        allow(Twilio::Security::RequestValidator).to receive(:new).with(auth_token).and_return(validator)
        allow(validator).to receive(:validate).and_return(false)
      end

      it "returns unauthorized status" do
        post webhooks_twilio_inbound_path, params: twilio_params, headers: { 'X-Twilio-Signature' => 'invalid_signature' }
        expect(response).to have_http_status(:unauthorized)
      end

      it "does not create a message" do
        expect {
          post webhooks_twilio_inbound_path, params: twilio_params, headers: { 'X-Twilio-Signature' => 'invalid_signature' }
        }.not_to change { Message.count }
      end
    end
  end

  describe "POST /webhooks/twilio/status" do
    let!(:message) { create(:message, twilio_sid: 'SM123456789', status: 'sent', business: business, customer: customer) }

    let(:status_params) {
      {
        'MessageSid' => 'SM123456789',
        'MessageStatus' => 'delivered'
      }
    }

    context "with valid Twilio signature" do
      before do
        # Mock Twilio signature validation
        validator = instance_double(Twilio::Security::RequestValidator)
        allow(Twilio::Security::RequestValidator).to receive(:new).with(auth_token).and_return(validator)
        allow(validator).to receive(:validate).and_return(true)
      end

      it "updates message status to queued" do
        status_params['MessageStatus'] = 'queued'
        post webhooks_twilio_status_path, params: status_params, headers: { 'X-Twilio-Signature' => 'valid_signature' }

        message.reload
        expect(message.status).to eq('queued')
      end

      it "updates message status to sent" do
        status_params['MessageStatus'] = 'sent'
        post webhooks_twilio_status_path, params: status_params, headers: { 'X-Twilio-Signature' => 'valid_signature' }

        message.reload
        expect(message.status).to eq('sent')
      end

      it "updates message status to delivered and sets delivered_at" do
        status_params['MessageStatus'] = 'delivered'

        post webhooks_twilio_status_path, params: status_params, headers: { 'X-Twilio-Signature' => 'valid_signature' }

        message.reload
        expect(message.status).to eq('delivered')
        expect(message.delivered_at).to be_present
        expect(message.delivered_at).to be_within(1.second).of(Time.current)
      end

      it "updates message status to failed with error message" do
        status_params['MessageStatus'] = 'failed'
        status_params['ErrorMessage'] = 'Invalid phone number'
        status_params['ErrorCode'] = '30004'

        post webhooks_twilio_status_path, params: status_params, headers: { 'X-Twilio-Signature' => 'valid_signature' }

        message.reload
        expect(message.status).to eq('failed')
        expect(message.error_message).to eq('Invalid phone number')
      end

      it "updates message status to undelivered with error code when no error message" do
        status_params['MessageStatus'] = 'undelivered'
        status_params['ErrorCode'] = '30006'

        post webhooks_twilio_status_path, params: status_params, headers: { 'X-Twilio-Signature' => 'valid_signature' }

        message.reload
        expect(message.status).to eq('undelivered')
        expect(message.error_message).to eq('Error code: 30006')
      end

      it "returns OK response" do
        post webhooks_twilio_status_path, params: status_params, headers: { 'X-Twilio-Signature' => 'valid_signature' }
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('OK')
      end

      it "handles unknown message gracefully" do
        status_params['MessageSid'] = 'SM_UNKNOWN'

        post webhooks_twilio_status_path, params: status_params, headers: { 'X-Twilio-Signature' => 'valid_signature' }

        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid Twilio signature" do
      before do
        # Mock invalid signature validation
        validator = instance_double(Twilio::Security::RequestValidator)
        allow(Twilio::Security::RequestValidator).to receive(:new).with(auth_token).and_return(validator)
        allow(validator).to receive(:validate).and_return(false)
      end

      it "returns unauthorized status" do
        post webhooks_twilio_status_path, params: status_params, headers: { 'X-Twilio-Signature' => 'invalid_signature' }
        expect(response).to have_http_status(:unauthorized)
      end

      it "does not update the message" do
        original_status = message.status

        post webhooks_twilio_status_path, params: status_params, headers: { 'X-Twilio-Signature' => 'invalid_signature' }

        message.reload
        expect(message.status).to eq(original_status)
      end
    end
  end
end
