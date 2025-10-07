require 'rails_helper'

RSpec.describe ConsentLog, type: :model do
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
      consent_log = ConsentLog.new(
        customer: customer,
        consent_text: 'I agree to receive SMS notifications',
        consented_at: Time.current
      )
      expect(consent_log).to be_valid
    end

    it 'is invalid without a customer' do
      consent_log = ConsentLog.new(
        consent_text: 'I agree to receive SMS notifications',
        consented_at: Time.current
      )
      expect(consent_log).not_to be_valid
      expect(consent_log.errors[:customer]).to include("must exist")
    end

    it 'is invalid without consent_text' do
      consent_log = ConsentLog.new(
        customer: customer,
        consented_at: Time.current
      )
      expect(consent_log).not_to be_valid
      expect(consent_log.errors[:consent_text]).to include("can't be blank")
    end

    it 'is invalid without consented_at' do
      consent_log = ConsentLog.new(
        customer: customer,
        consent_text: 'I agree to receive SMS notifications'
      )
      expect(consent_log).not_to be_valid
      expect(consent_log.errors[:consented_at]).to include("can't be blank")
    end
  end

  describe 'associations' do
    it 'belongs to a customer' do
      association = ConsentLog.reflect_on_association(:customer)
      expect(association.macro).to eq(:belongs_to)
    end
  end
end
