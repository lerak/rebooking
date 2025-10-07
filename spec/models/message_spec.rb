require 'rails_helper'

RSpec.describe Message, type: :model do
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
      message = Message.new(
        customer: customer,
        body: 'Hello, this is a test message',
        direction: :inbound,
        status: :received,
        business: business
      )
      expect(message).to be_valid
    end

    it 'is invalid without a customer' do
      message = Message.new(
        body: 'Hello, this is a test message',
        direction: :inbound,
        status: :received,
        business: business
      )
      expect(message).not_to be_valid
      expect(message.errors[:customer]).to include("must exist")
    end

    it 'is invalid without a body' do
      message = Message.new(
        customer: customer,
        direction: :inbound,
        status: :received,
        business: business
      )
      expect(message).not_to be_valid
      expect(message.errors[:body]).to include("can't be blank")
    end

    it 'is invalid without a direction' do
      message = Message.new(
        customer: customer,
        body: 'Hello, this is a test message',
        status: :received,
        business: business
      )
      expect(message).not_to be_valid
      expect(message.errors[:direction]).to include("can't be blank")
    end

    it 'is invalid without a business' do
      message = Message.new(
        customer: customer,
        body: 'Hello, this is a test message',
        direction: :inbound,
        status: :received
      )
      expect(message).not_to be_valid
      expect(message.errors[:business]).to include("must exist")
    end
  end

  describe 'associations' do
    it 'belongs to a customer' do
      association = Message.reflect_on_association(:customer)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'belongs to a business' do
      association = Message.reflect_on_association(:business)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'directions' do
    it 'can be inbound' do
      message = Message.create!(
        customer: customer,
        body: 'Hello, this is a test message',
        direction: :inbound,
        status: :received,
        business: business
      )
      expect(message.inbound?).to be true
      expect(message.outbound?).to be false
    end

    it 'can be outbound' do
      message = Message.create!(
        customer: customer,
        body: 'Hello, this is a test message',
        direction: :outbound,
        status: :sent,
        business: business
      )
      expect(message.outbound?).to be true
      expect(message.inbound?).to be false
    end
  end

  describe 'statuses' do
    it 'can be received' do
      message = Message.create!(
        customer: customer,
        body: 'Hello, this is a test message',
        direction: :inbound,
        status: :received,
        business: business
      )
      expect(message.received?).to be true
    end

    it 'can be sent' do
      message = Message.create!(
        customer: customer,
        body: 'Hello, this is a test message',
        direction: :outbound,
        status: :sent,
        business: business
      )
      expect(message.sent?).to be true
    end

    it 'can be failed' do
      message = Message.create!(
        customer: customer,
        body: 'Hello, this is a test message',
        direction: :outbound,
        status: :failed,
        business: business
      )
      expect(message.failed?).to be true
    end

    it 'defaults to received status if not specified' do
      message = Message.create!(
        customer: customer,
        body: 'Hello, this is a test message',
        direction: :inbound,
        business: business
      )
      expect(message.received?).to be true
    end
  end

  describe 'tenant scoping' do
    it 'is scoped to business tenant' do
      expect(Message.ancestors).to include(ActsAsTenant::ModelExtensions)
    end
  end
end
