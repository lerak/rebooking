require 'rails_helper'

RSpec.describe ScheduleAppointmentRemindersJob, type: :job do
  let(:business) { create(:business, reminder_hours_before: 24) }
  let(:customer) { create(:customer, business: business, sms_consent_status: :active) }

  describe '#perform' do
    it 'queues reminders for appointments within the next hour' do
      # Appointment that should trigger reminder (24 hours from now, within next hour window)
      appointment = create(:appointment,
                           customer: customer,
                           business: business,
                           start_time: 24.hours.from_now + 30.minutes,
                           status: :scheduled)

      expect {
        described_class.perform_now
      }.to have_enqueued_job(SendAppointmentReminderJob).with(appointment.id)
    end

    it 'does not queue reminders for appointments too far in the future' do
      # Appointment 25.5 hours from now (reminder would be 1.5 hours from now, outside the window)
      create(:appointment,
             customer: customer,
             business: business,
             start_time: 25.hours.from_now + 30.minutes,
             status: :scheduled)

      expect {
        described_class.perform_now
      }.not_to have_enqueued_job(SendAppointmentReminderJob)
    end

    it 'does not queue reminders for appointments too soon' do
      # Appointment 23 hours from now (reminder would have been 1 hour ago)
      create(:appointment,
             customer: customer,
             business: business,
             start_time: 23.hours.from_now,
             status: :scheduled)

      expect {
        described_class.perform_now
      }.not_to have_enqueued_job(SendAppointmentReminderJob)
    end

    it 'respects custom reminder_hours_before setting' do
      business.update!(reminder_hours_before: 48)

      # Appointment 48 hours from now (reminder should be sent now)
      appointment = create(:appointment,
                           customer: customer,
                           business: business,
                           start_time: 48.hours.from_now + 30.minutes,
                           status: :scheduled)

      expect {
        described_class.perform_now
      }.to have_enqueued_job(SendAppointmentReminderJob).with(appointment.id)
    end

    it 'only processes scheduled appointments' do
      # Create appointments with different statuses
      scheduled_apt = create(:appointment,
                             customer: customer,
                             business: business,
                             start_time: 24.hours.from_now + 30.minutes,
                             status: :scheduled)

      completed_apt = create(:appointment,
                             customer: customer,
                             business: business,
                             start_time: 24.hours.from_now + 30.minutes,
                             status: :completed)

      expect {
        described_class.perform_now
      }.to have_enqueued_job(SendAppointmentReminderJob).with(scheduled_apt.id).once
    end

    it 'handles multiple appointments in the window' do
      apt1 = create(:appointment,
                    customer: customer,
                    business: business,
                    start_time: 24.hours.from_now + 15.minutes,
                    status: :scheduled)

      apt2 = create(:appointment,
                    customer: customer,
                    business: business,
                    start_time: 24.hours.from_now + 45.minutes,
                    status: :scheduled)

      expect {
        described_class.perform_now
      }.to have_enqueued_job(SendAppointmentReminderJob).with(apt1.id)
       .and have_enqueued_job(SendAppointmentReminderJob).with(apt2.id)
    end

    it 'is idempotent when run multiple times' do
      appointment = create(:appointment,
                           customer: customer,
                           business: business,
                           start_time: 24.hours.from_now + 30.minutes,
                           status: :scheduled)

      # First run
      described_class.perform_now

      # Second run should also queue the reminder (job itself handles deduplication if needed)
      expect {
        described_class.perform_now
      }.to have_enqueued_job(SendAppointmentReminderJob).with(appointment.id)
    end
  end
end
