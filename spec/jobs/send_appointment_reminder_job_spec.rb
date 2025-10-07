require 'rails_helper'

RSpec.describe SendAppointmentReminderJob, type: :job do
  let(:business) { create(:business, name: 'Test Clinic') }
  let(:customer) { create(:customer, business: business, sms_consent_status: :active) }
  let(:appointment) do
    create(:appointment,
           customer: customer,
           business: business,
           start_time: 1.day.from_now.change(hour: 14, min: 30),
           status: :scheduled)
  end

  describe '#perform' do
    it 'queues a SendMessageJob with formatted reminder message' do
      expect {
        described_class.perform_now(appointment.id)
      }.to have_enqueued_job(SendMessageJob).with(
        customer.id,
        /Reminder: You have an appointment on/,
        business.id
      )
    end

    it 'formats the reminder message with appointment details' do
      allow(SendMessageJob).to receive(:perform_later)

      described_class.perform_now(appointment.id)

      expected_time = appointment.start_time.strftime('%B %d at %I:%M %p')
      expected_message = "Reminder: You have an appointment on #{expected_time} with Test Clinic."

      expect(SendMessageJob).to have_received(:perform_later).with(
        customer.id,
        expected_message,
        business.id
      )
    end

    it 'includes business name in the reminder' do
      allow(SendMessageJob).to receive(:perform_later)

      described_class.perform_now(appointment.id)

      expect(SendMessageJob).to have_received(:perform_later).with(
        customer.id,
        /Test Clinic/,
        business.id
      )
    end
  end
end
