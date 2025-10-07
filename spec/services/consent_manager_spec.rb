require 'rails_helper'

RSpec.describe ConsentManager, type: :service do
  let(:business) { create(:business) }
  let(:customer) { create(:customer, business: business, sms_consent_status: :active) }
  let(:consent_manager) { described_class.new(customer) }

  describe '#opt_in' do
    context 'when customer is not opted out' do
      it 'sets customer status to active' do
        customer.update!(sms_consent_status: :pending)
        consent_manager.opt_in

        expect(customer.reload.sms_consent_status).to eq('active')
      end

      it 'clears opted_out_at timestamp' do
        customer.update!(opted_out_at: 1.day.ago)
        consent_manager.opt_in

        expect(customer.reload.opted_out_at).to be_nil
      end

      it 'creates an opt-in consent log' do
        expect {
          consent_manager.opt_in
        }.to change { customer.consent_logs.count }.by(1)

        log = customer.consent_logs.order(created_at: :desc).first
        expect(log.event_type).to eq('opted_in')
        expect(log.consented_at).to be_present
      end

      it 'uses provided consent text' do
        consent_manager.opt_in(consent_text: 'Customer agreed via web form')

        log = customer.consent_logs.order(created_at: :desc).first
        expect(log.consent_text).to eq('Customer agreed via web form')
      end

      it 'uses default consent text when not provided' do
        consent_manager.opt_in

        log = customer.consent_logs.order(created_at: :desc).first
        expect(log.consent_text).to eq('Customer provided phone number and consented to SMS notifications')
      end

      it 'stores metadata in consent log' do
        initial_count = customer.consent_logs.count
        consent_manager.opt_in(metadata: { source: 'web', ip: '127.0.0.1' })

        expect(customer.consent_logs.count).to eq(initial_count + 1)
        log = customer.consent_logs.order(created_at: :desc).first
        expect(log.metadata).to eq({ 'source' => 'web', 'ip' => '127.0.0.1' })
      end

      it 'returns true on success' do
        result = consent_manager.opt_in
        expect(result).to be true
      end

      it 'performs updates in a transaction' do
        allow(customer).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)

        expect {
          consent_manager.opt_in
        }.not_to change { customer.consent_logs.count }
      end
    end

    context 'when customer is already opted out' do
      before do
        customer.update!(sms_consent_status: :opted_out, opted_out_at: Time.current)
      end

      it 'returns false' do
        result = consent_manager.opt_in
        expect(result).to be false
      end

      it 'does not change customer status' do
        consent_manager.opt_in
        expect(customer.reload.sms_consent_status).to eq('opted_out')
      end

      it 'does not create a consent log' do
        expect {
          consent_manager.opt_in
        }.not_to change { customer.consent_logs.count }
      end
    end
  end

  describe '#opt_out' do
    context 'when customer can receive SMS' do
      it 'sets customer status to opted_out' do
        consent_manager.opt_out

        expect(customer.reload.sms_consent_status).to eq('opted_out')
      end

      it 'sets opted_out_at timestamp' do
        consent_manager.opt_out

        expect(customer.reload.opted_out_at).to be_present
        expect(customer.opted_out_at).to be_within(1.second).of(Time.current)
      end

      it 'creates an opt-out consent log' do
        initial_count = customer.consent_logs.count
        consent_manager.opt_out

        expect(customer.consent_logs.count).to eq(initial_count + 1)
        log = customer.consent_logs.order(created_at: :desc).first
        expect(log.event_type).to eq('opted_out')
        expect(log.consented_at).to be_present
      end

      it 'uses provided reason text' do
        consent_manager.opt_out(reason: 'Customer replied STOP')

        log = customer.consent_logs.order(created_at: :desc).first
        expect(log.consent_text).to eq('Customer replied STOP')
      end

      it 'uses default reason when not provided' do
        consent_manager.opt_out

        log = customer.consent_logs.order(created_at: :desc).first
        expect(log.consent_text).to eq('Customer opted out')
      end

      it 'stores metadata in consent log' do
        consent_manager.opt_out(metadata: { keyword: 'STOP', message_sid: 'SM123' })

        log = customer.consent_logs.order(created_at: :desc).first
        expect(log.metadata).to eq({ 'keyword' => 'STOP', 'message_sid' => 'SM123' })
      end

      it 'returns true on success' do
        result = consent_manager.opt_out
        expect(result).to be true
      end

      it 'performs updates in a transaction' do
        allow(customer).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)

        expect {
          consent_manager.opt_out
        }.not_to change { customer.consent_logs.count }
      end
    end

    context 'when customer cannot receive SMS' do
      before do
        customer.update!(sms_consent_status: :opted_out)
      end

      it 'returns false' do
        result = consent_manager.opt_out
        expect(result).to be false
      end

      it 'does not create a consent log' do
        expect {
          consent_manager.opt_out
        }.not_to change { customer.consent_logs.count }
      end
    end

    context 'when customer status is pending' do
      before do
        customer.update!(sms_consent_status: :pending)
      end

      it 'returns false' do
        result = consent_manager.opt_out
        expect(result).to be false
      end

      it 'does not change customer status' do
        consent_manager.opt_out
        expect(customer.reload.sms_consent_status).to eq('pending')
      end
    end
  end
end
