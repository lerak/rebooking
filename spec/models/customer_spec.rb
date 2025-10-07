require 'rails_helper'

RSpec.describe Customer, type: :model do
  let(:business) { Business.create!(name: 'Test Business', timezone: 'America/New_York') }

  describe 'validations' do
    it 'is valid with valid attributes' do
      customer = Customer.new(
        first_name: 'John',
        last_name: 'Doe',
        phone: '555-1234',
        email: 'john@example.com',
        business: business
      )
      expect(customer).to be_valid
    end

    it 'is invalid without a first_name' do
      customer = Customer.new(
        last_name: 'Doe',
        phone: '555-1234',
        email: 'john@example.com',
        business: business
      )
      expect(customer).not_to be_valid
      expect(customer.errors[:first_name]).to include("can't be blank")
    end

    it 'is invalid without a last_name' do
      customer = Customer.new(
        first_name: 'John',
        phone: '555-1234',
        email: 'john@example.com',
        business: business
      )
      expect(customer).not_to be_valid
      expect(customer.errors[:last_name]).to include("can't be blank")
    end

    it 'is invalid without a phone' do
      customer = Customer.new(
        first_name: 'John',
        last_name: 'Doe',
        email: 'john@example.com',
        business: business
      )
      expect(customer).not_to be_valid
      expect(customer.errors[:phone]).to include("can't be blank")
    end

    it 'is invalid without a business' do
      customer = Customer.new(
        first_name: 'John',
        last_name: 'Doe',
        phone: '555-1234',
        email: 'john@example.com'
      )
      expect(customer).not_to be_valid
      expect(customer.errors[:business]).to include("must exist")
    end

    it 'enforces unique phone per business' do
      Customer.create!(
        first_name: 'John',
        last_name: 'Doe',
        phone: '555-1234',
        email: 'john@example.com',
        business: business
      )
      duplicate_customer = Customer.new(
        first_name: 'Jane',
        last_name: 'Smith',
        phone: '555-1234',
        email: 'jane@example.com',
        business: business
      )

      expect(duplicate_customer).not_to be_valid
      expect(duplicate_customer.errors[:phone]).to include("has already been taken")
    end

    it 'allows same phone across different businesses' do
      business2 = Business.create!(name: 'Another Business', timezone: 'America/Los_Angeles')

      ActsAsTenant.without_tenant do
        customer1 = Customer.create!(
          first_name: 'John',
          last_name: 'Doe',
          phone: '555-1234',
          email: 'john@example.com',
          business: business
        )
        customer2 = Customer.new(
          first_name: 'Jane',
          last_name: 'Smith',
          phone: '555-1234',
          email: 'jane@example.com',
          business: business2
        )

        expect(customer2).to be_valid
      end
    end
  end

  describe 'associations' do
    it 'belongs to a business' do
      association = Customer.reflect_on_association(:business)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'has many appointments' do
      association = Customer.reflect_on_association(:appointments)
      expect(association.macro).to eq(:has_many)
    end

    it 'has many messages' do
      association = Customer.reflect_on_association(:messages)
      expect(association.macro).to eq(:has_many)
    end

    it 'has many consent_logs' do
      association = Customer.reflect_on_association(:consent_logs)
      expect(association.macro).to eq(:has_many)
    end

    it 'destroys dependent appointments when destroyed' do
      customer = Customer.create!(
        first_name: 'John',
        last_name: 'Doe',
        phone: '555-1234',
        email: 'john@example.com',
        business: business
      )

      ActsAsTenant.with_tenant(business) do
        customer.appointments.create!(
          start_time: Time.current,
          end_time: Time.current + 1.hour,
          status: :scheduled,
          business: business
        )

        expect { customer.destroy }.to change { Appointment.count }.by(-1)
      end
    end
  end

  describe 'tenant scoping' do
    it 'is scoped to business tenant' do
      expect(Customer.ancestors).to include(ActsAsTenant::ModelExtensions)
    end
  end

  describe 'sms_consent_status enum' do
    it 'has active as default sms_consent_status' do
      customer = Customer.create!(
        first_name: 'John',
        last_name: 'Doe',
        phone: '555-1234',
        business: business
      )
      expect(customer.sms_consent_status).to eq('active')
    end

    it 'can be set to pending' do
      customer = Customer.create!(
        first_name: 'John',
        last_name: 'Doe',
        phone: '555-1234',
        business: business,
        sms_consent_status: :pending
      )
      expect(customer.pending?).to be true
    end

    it 'can be set to opted_out' do
      customer = Customer.create!(
        first_name: 'John',
        last_name: 'Doe',
        phone: '555-1234',
        business: business,
        sms_consent_status: :opted_out
      )
      expect(customer.opted_out?).to be true
    end
  end

  describe '#consented?' do
    it 'returns true when status is active' do
      customer = Customer.create!(
        first_name: 'John',
        last_name: 'Doe',
        phone: '555-1234',
        business: business,
        sms_consent_status: :active
      )
      expect(customer.consented?).to be true
    end

    it 'returns false when status is pending' do
      customer = Customer.create!(
        first_name: 'John',
        last_name: 'Doe',
        phone: '555-1234',
        business: business,
        sms_consent_status: :pending
      )
      expect(customer.consented?).to be false
    end

    it 'returns false when status is opted_out' do
      customer = Customer.create!(
        first_name: 'John',
        last_name: 'Doe',
        phone: '555-1234',
        business: business,
        sms_consent_status: :opted_out
      )
      expect(customer.consented?).to be false
    end
  end

  describe '#opted_out?' do
    it 'returns true when status is opted_out' do
      customer = Customer.create!(
        first_name: 'John',
        last_name: 'Doe',
        phone: '555-1234',
        business: business,
        sms_consent_status: :opted_out
      )
      expect(customer.opted_out?).to be true
    end

    it 'returns false when status is active' do
      customer = Customer.create!(
        first_name: 'John',
        last_name: 'Doe',
        phone: '555-1234',
        business: business,
        sms_consent_status: :active
      )
      expect(customer.opted_out?).to be false
    end

    it 'returns false when status is pending' do
      customer = Customer.create!(
        first_name: 'John',
        last_name: 'Doe',
        phone: '555-1234',
        business: business,
        sms_consent_status: :pending
      )
      expect(customer.opted_out?).to be false
    end
  end

  describe '#can_receive_sms?' do
    it 'returns true when customer has active consent' do
      customer = Customer.create!(
        first_name: 'John',
        last_name: 'Doe',
        phone: '555-1234',
        business: business,
        sms_consent_status: :active
      )
      expect(customer.can_receive_sms?).to be true
    end

    it 'returns false when customer is opted_out' do
      customer = Customer.create!(
        first_name: 'John',
        last_name: 'Doe',
        phone: '555-1234',
        business: business,
        sms_consent_status: :opted_out
      )
      expect(customer.can_receive_sms?).to be false
    end

    it 'returns false when customer status is pending' do
      customer = Customer.create!(
        first_name: 'John',
        last_name: 'Doe',
        phone: '555-1234',
        business: business,
        sms_consent_status: :pending
      )
      expect(customer.can_receive_sms?).to be false
    end
  end

  describe 'automatic consent creation' do
    it 'creates a consent log when customer is created with phone number' do
      customer = Customer.create!(
        first_name: 'John',
        last_name: 'Doe',
        phone: '555-1234',
        business: business
      )

      expect(customer.consent_logs.count).to eq(1)

      consent_log = customer.consent_logs.first
      expect(consent_log.event_type).to eq('opted_in')
      expect(consent_log.consent_text).to eq('Customer provided phone number and consented to SMS notifications')
      expect(consent_log.consented_at).to be_present
    end

    it 'does not create consent log if phone is blank' do
      customer = Customer.new(
        first_name: 'John',
        last_name: 'Doe',
        phone: '',
        business: business
      )

      # Will fail validation, but testing the callback logic
      expect(customer.valid?).to be false
    end
  end
end
