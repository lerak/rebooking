class SendAppointmentReminderJob < ApplicationJob
  queue_as :default

  def perform(appointment_id)
    appointment = Appointment.find(appointment_id)
    customer = appointment.customer
    business = appointment.business

    # Format the reminder message
    reminder_message = format_reminder_message(appointment)

    # Queue the message to be sent with appointment_id for location-based phone number
    SendMessageJob.perform_later(customer.id, reminder_message, business.id, appointment_id: appointment.id)
  end

  private

  def format_reminder_message(appointment)
    time_str = appointment.start_time.strftime('%B %d at %I:%M %p')
    "Reminder: You have an appointment on #{time_str} with #{appointment.business.name}."
  end
end
