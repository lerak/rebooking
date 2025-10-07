# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require 'faker'

puts "🌱 Starting seed process..."

# Clean up existing data (only in development)
if Rails.env.development?
  puts "🧹 Cleaning up existing data..."
  ConsentLog.destroy_all
  Message.destroy_all
  Appointment.destroy_all
  Customer.destroy_all
  User.destroy_all
  Business.destroy_all
end

# Create 5 businesses with users, customers, and appointments
5.times do |i|
  puts "\n📦 Creating Business #{i + 1}..."

  business = Business.create!(
    name: Faker::Company.name,
    timezone: ['America/New_York', 'America/Chicago', 'America/Denver', 'America/Los_Angeles', 'UTC'].sample
  )

  puts "  ✓ Business: #{business.name}"

  # Create 2-3 users per business
  users_count = rand(2..3)
  users_count.times do
    user = User.create!(
      email: Faker::Internet.unique.email,
      password: 'password123',
      password_confirmation: 'password123',
      role: ['admin', 'staff'].sample,
      business: business
    )
    puts "    ✓ User: #{user.email} (#{user.role})"
  end

  # Create 10-15 customers per business
  customers_count = rand(10..15)
  customers = []
  customers_count.times do
    customer = Customer.create!(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      email: Faker::Internet.unique.email,
      phone: Faker::PhoneNumber.phone_number,
      business: business
    )
    customers << customer
  end
  puts "    ✓ Created #{customers_count} customers"

  # Create 15-25 appointments per business
  appointments_count = rand(15..25)
  appointments_count.times do
    customer = customers.sample
    start_time = Faker::Time.between(from: 30.days.ago, to: 30.days.from_now)

    appointment = Appointment.create!(
      customer: customer,
      start_time: start_time,
      end_time: start_time + rand(30..120).minutes,
      status: ['scheduled', 'confirmed', 'completed', 'cancelled'].sample,
      business: business
    )
  end
  puts "    ✓ Created #{appointments_count} appointments"

  # Create 20-30 messages per business
  messages_count = rand(20..30)
  messages_count.times do
    customer = customers.sample

    message = Message.create!(
      customer: customer,
      body: Faker::Lorem.sentence(word_count: rand(5..20)),
      direction: ['inbound', 'outbound'].sample,
      status: ['received', 'sent', 'failed'].sample,
      metadata: {
        sent_at: Faker::Time.between(from: 7.days.ago, to: Time.current),
        provider: ['twilio', 'messagebird'].sample
      },
      business: business
    )
  end
  puts "    ✓ Created #{messages_count} messages"

  # Create 5-10 consent logs per business
  consent_logs_count = rand(5..10)
  consent_logs_count.times do
    customer = customers.sample

    ConsentLog.create!(
      customer: customer,
      consent_text: "I agree to receive appointment reminders via SMS and email.",
      consented_at: Faker::Time.between(from: 90.days.ago, to: Time.current)
    )
  end
  puts "    ✓ Created #{consent_logs_count} consent logs"
end

puts "\n✅ Seed process complete!"
puts "\n📊 Summary:"
puts "  Businesses: #{Business.count}"
puts "  Users: #{User.count}"
puts "  Customers: #{Customer.count}"
puts "  Appointments: #{Appointment.count}"
puts "  Messages: #{Message.count}"
puts "  Consent Logs: #{ConsentLog.count}"
puts "\n🔐 Default password for all users: password123"
