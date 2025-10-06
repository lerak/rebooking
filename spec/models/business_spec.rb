require 'rails_helper'

RSpec.describe Business, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      business = Business.new(name: 'Test Business', timezone: 'America/New_York')
      expect(business).to be_valid
    end

    it 'is invalid without a name' do
      business = Business.new(timezone: 'America/New_York')
      expect(business).not_to be_valid
      expect(business.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without a timezone' do
      business = Business.new(name: 'Test Business')
      expect(business).not_to be_valid
      expect(business.errors[:timezone]).to include("can't be blank")
    end
  end

  describe 'associations' do
    it 'has many users' do
      association = Business.reflect_on_association(:users)
      expect(association.macro).to eq(:has_many)
    end

    # Will be tested in task 3.0 when models are created
    # it 'has many customers' do
    #   association = Business.reflect_on_association(:customers)
    #   expect(association.macro).to eq(:has_many)
    # end

    # it 'has many appointments' do
    #   association = Business.reflect_on_association(:appointments)
    #   expect(association.macro).to eq(:has_many)
    # end

    # it 'has many messages' do
    #   association = Business.reflect_on_association(:messages)
    #   expect(association.macro).to eq(:has_many)
    # end

    it 'destroys dependent users when destroyed' do
      business = Business.create!(name: 'Test Business', timezone: 'America/New_York')
      user = business.users.create!(email: 'test@example.com', password: 'password123', role: :admin)

      expect { business.destroy }.to change { User.count }.by(-1)
    end
  end
end
