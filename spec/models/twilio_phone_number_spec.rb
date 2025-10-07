require 'rails_helper'

RSpec.describe TwilioPhoneNumber, type: :model do
  let(:business) { create(:business) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      phone_number = TwilioPhoneNumber.new(
        business: business,
        phone_number: '+15555551234',
        location: 'Downtown Office',
        status: :pending
      )
      expect(phone_number).to be_valid
    end

    it 'is invalid without a phone_number' do
      phone_number = TwilioPhoneNumber.new(
        business: business,
        location: 'Downtown Office'
      )
      expect(phone_number).not_to be_valid
      expect(phone_number.errors[:phone_number]).to include("can't be blank")
    end

    it 'is invalid without a location' do
      phone_number = TwilioPhoneNumber.new(
        business: business,
        phone_number: '+15555551234'
      )
      expect(phone_number).not_to be_valid
      expect(phone_number.errors[:location]).to include("can't be blank")
    end

    it 'enforces unique phone_number globally' do
      TwilioPhoneNumber.create!(
        business: business,
        phone_number: '+15555551234',
        location: 'Office A'
      )

      duplicate = TwilioPhoneNumber.new(
        business: business,
        phone_number: '+15555551234',
        location: 'Office B'
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:phone_number]).to include('has already been taken')
    end
  end

  describe 'associations' do
    it 'belongs to a business' do
      association = TwilioPhoneNumber.reflect_on_association(:business)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'status enum' do
    it 'has pending status by default' do
      phone_number = TwilioPhoneNumber.create!(
        business: business,
        phone_number: '+15555551234',
        location: 'Downtown Office'
      )
      expect(phone_number.pending?).to be true
    end

    it 'can be set to approved' do
      phone_number = TwilioPhoneNumber.create!(
        business: business,
        phone_number: '+15555551234',
        location: 'Downtown Office',
        status: :approved
      )
      expect(phone_number.approved?).to be true
      expect(phone_number.pending?).to be false
    end

    it 'can be set to active' do
      phone_number = TwilioPhoneNumber.create!(
        business: business,
        phone_number: '+15555551234',
        location: 'Downtown Office',
        status: :active
      )
      expect(phone_number.active?).to be true
      expect(phone_number.pending?).to be false
    end

    it 'can query by status' do
      pending_number = TwilioPhoneNumber.create!(
        business: business,
        phone_number: '+15555551234',
        location: 'Office A',
        status: :pending
      )

      active_number = TwilioPhoneNumber.create!(
        business: business,
        phone_number: '+15555551235',
        location: 'Office B',
        status: :active
      )

      expect(TwilioPhoneNumber.pending).to include(pending_number)
      expect(TwilioPhoneNumber.pending).not_to include(active_number)
      expect(TwilioPhoneNumber.active).to include(active_number)
      expect(TwilioPhoneNumber.active).not_to include(pending_number)
    end
  end

  describe 'admin approval methods' do
    let(:phone_number) do
      TwilioPhoneNumber.create!(
        business: business,
        phone_number: '+15555551234',
        location: 'Downtown Office',
        status: :pending
      )
    end

    describe '#approve!' do
      it 'changes status from pending to approved' do
        expect { phone_number.approve! }.to change { phone_number.status }.from('pending').to('approved')
      end

      it 'persists the status change' do
        phone_number.approve!
        phone_number.reload
        expect(phone_number.approved?).to be true
      end
    end

    describe '#activate!' do
      it 'changes status to active' do
        expect { phone_number.activate! }.to change { phone_number.status }.from('pending').to('active')
      end

      it 'persists the status change' do
        phone_number.activate!
        phone_number.reload
        expect(phone_number.active?).to be true
      end
    end

    describe '#reject!' do
      it 'deletes the phone number request' do
        phone_number_id = phone_number.id
        phone_number.reject!
        expect(TwilioPhoneNumber.find_by(id: phone_number_id)).to be_nil
      end
    end
  end
end
