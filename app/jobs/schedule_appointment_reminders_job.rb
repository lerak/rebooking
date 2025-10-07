class ScheduleAppointmentRemindersJob < ApplicationJob
  queue_as :default

  def perform
    # Find all upcoming appointments that need reminders
    Appointment.includes(:business, :customer).find_each do |appointment|
      next unless appointment.scheduled?

      business = appointment.business
      hours_before = business.reminder_hours_before || 24

      # Calculate when the reminder should be sent
      reminder_time = appointment.start_time - hours_before.hours

      # Only schedule if reminder time is in the next hour
      if reminder_time.between?(Time.current, 1.hour.from_now)
        SendAppointmentReminderJob.perform_later(appointment.id)
      end
    end
  end
end
