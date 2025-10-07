require 'rails_helper'

RSpec.describe 'Appointment Reminders', type: :system do
  include ActiveJob::TestHelper

  let(:business) { create(:business, name: 'Test Clinic', reminder_hours_before: 24, twilio_phone_number: '+1234567890') }
  let(:user) { create(:user, business: business) }
  let(:customer) { create(:customer, business: business, phone: '+19876543210', sms_consent_status: :active) }

  before do
    sign_in_user user
  end

  describe 'end-to-end reminder flow' do
    it 'respects customer consent status when sending messages' do
      # Create customer without consent
      opted_out_customer = create(:customer,
                                   business: business,
                                   phone: '+19998887777',
                                   sms_consent_status: :opted_out)

      # When SendMessageJob runs, it should skip this customer
      expect {
        SendMessageJob.perform_now(opted_out_customer.id, 'Test message', business.id)
      }.not_to change { Message.count }
    end

    it 'creates message record when reminder is sent with consent' do
      appointment = create(:appointment,
                          customer: customer,
                          business: business,
                          start_time: 1.day.from_now.change(hour: 14, min: 30),
                          status: :scheduled)

      # Stub TwilioService to avoid actual API calls
      twilio_service = instance_double(TwilioService)
      twilio_message = double('Twilio::Message', sid: 'SM123456')
      allow(TwilioService).to receive(:new).and_return(twilio_service)
      allow(twilio_service).to receive(:send_sms).and_return(twilio_message)

      # Trigger the reminder job chain
      expect {
        SendAppointmentReminderJob.perform_now(appointment.id)
        # This queues SendMessageJob, so we need to perform it
        perform_enqueued_jobs(only: SendMessageJob)
      }.to change { Message.count }.by(1)

      message = Message.last
      expect(message.customer).to eq(customer)
      expect(message.business).to eq(business)
      expect(message.direction).to eq('outbound')
      expect(message.status).to eq('sent')
      expect(message.body).to include('Reminder')
      expect(message.body).to include('Test Clinic')
      expect(message.twilio_sid).to eq('SM123456')
    end

    it 'verifies scheduled appointments can trigger reminders' do
      # Create appointment that would trigger reminder
      appointment = create(:appointment,
                          customer: customer,
                          business: business,
                          start_time: 24.hours.from_now + 30.minutes,
                          status: :scheduled)

      # Verify ScheduleAppointmentRemindersJob would pick this up
      reminder_time = appointment.start_time - business.reminder_hours_before.hours
      expect(reminder_time).to be_between(Time.current, 1.hour.from_now)

      # Verify the job would queue the reminder
      expect {
        ScheduleAppointmentRemindersJob.perform_now
      }.to have_enqueued_job(SendAppointmentReminderJob).with(appointment.id)
    end
  end

  describe 'scheduling configuration' do
    it 'allows business to configure reminder hours' do
      visit edit_settings_business_path(business)

      fill_in 'business[reminder_hours_before]', with: '48'

      click_button 'Update Business Settings'

      expect(page).to have_content('Business settings updated successfully')

      business.reload
      expect(business.reminder_hours_before).to eq(48)
    end

    it 'validates reminder hours are positive' do
      business.update!(reminder_hours_before: 24)

      visit edit_settings_business_path(business)

      fill_in 'business[reminder_hours_before]', with: '-1'

      click_button 'Update Business Settings'

      expect(page).to have_content('must be greater than 0')
    end
  end
end
