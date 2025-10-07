require 'rails_helper'

RSpec.describe Appointment, type: :model do
  let(:business) { Business.create!(name: 'Test Business', timezone: 'America/New_York') }
  let(:customer) do
    Customer.create!(
      first_name: 'John',
      last_name: 'Doe',
      phone: '555-1234',
      email: 'john@example.com',
      business: business
    )
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      appointment = Appointment.new(
        customer: customer,
        start_time: Time.current,
        end_time: Time.current + 1.hour,
        status: :scheduled,
        business: business
      )
      expect(appointment).to be_valid
    end

    it 'is invalid without a customer' do
      appointment = Appointment.new(
        start_time: Time.current,
        end_time: Time.current + 1.hour,
        status: :scheduled,
        business: business
      )
      expect(appointment).not_to be_valid
      expect(appointment.errors[:customer]).to include("must exist")
    end

    it 'is invalid without a start_time' do
      appointment = Appointment.new(
        customer: customer,
        end_time: Time.current + 1.hour,
        status: :scheduled,
        business: business
      )
      expect(appointment).not_to be_valid
      expect(appointment.errors[:start_time]).to include("can't be blank")
    end

    it 'is invalid without an end_time' do
      appointment = Appointment.new(
        customer: customer,
        start_time: Time.current,
        status: :scheduled,
        business: business
      )
      expect(appointment).not_to be_valid
      expect(appointment.errors[:end_time]).to include("can't be blank")
    end

    it 'is invalid without a business' do
      appointment = Appointment.new(
        customer: customer,
        start_time: Time.current,
        end_time: Time.current + 1.hour,
        status: :scheduled
      )
      expect(appointment).not_to be_valid
      expect(appointment.errors[:business]).to include("must exist")
    end

    it 'is invalid when end_time is before start_time' do
      appointment = Appointment.new(
        customer: customer,
        start_time: Time.current + 1.hour,
        end_time: Time.current,
        status: :scheduled,
        business: business
      )
      expect(appointment).not_to be_valid
      expect(appointment.errors[:end_time]).to include("must be after start time")
    end
  end

  describe 'associations' do
    it 'belongs to a customer' do
      association = Appointment.reflect_on_association(:customer)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'belongs to a business' do
      association = Appointment.reflect_on_association(:business)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'statuses' do
    it 'can be scheduled' do
      appointment = Appointment.create!(
        customer: customer,
        start_time: Time.current,
        end_time: Time.current + 1.hour,
        status: :scheduled,
        business: business
      )
      expect(appointment.scheduled?).to be true
      expect(appointment.confirmed?).to be false
      expect(appointment.completed?).to be false
      expect(appointment.cancelled?).to be false
    end

    it 'can be confirmed' do
      appointment = Appointment.create!(
        customer: customer,
        start_time: Time.current,
        end_time: Time.current + 1.hour,
        status: :confirmed,
        business: business
      )
      expect(appointment.confirmed?).to be true
      expect(appointment.scheduled?).to be false
    end

    it 'can be completed' do
      appointment = Appointment.create!(
        customer: customer,
        start_time: Time.current,
        end_time: Time.current + 1.hour,
        status: :completed,
        business: business
      )
      expect(appointment.completed?).to be true
      expect(appointment.scheduled?).to be false
    end

    it 'can be cancelled' do
      appointment = Appointment.create!(
        customer: customer,
        start_time: Time.current,
        end_time: Time.current + 1.hour,
        status: :cancelled,
        business: business
      )
      expect(appointment.cancelled?).to be true
      expect(appointment.scheduled?).to be false
    end

    it 'defaults to scheduled status if not specified' do
      appointment = Appointment.create!(
        customer: customer,
        start_time: Time.current,
        end_time: Time.current + 1.hour,
        business: business
      )
      expect(appointment.scheduled?).to be true
    end
  end

  describe 'tenant scoping' do
    it 'is scoped to business tenant' do
      expect(Appointment.ancestors).to include(ActsAsTenant::ModelExtensions)
    end
  end
end
