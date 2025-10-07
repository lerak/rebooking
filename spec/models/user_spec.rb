require 'rails_helper'

RSpec.describe User, type: :model do
  let(:business) { Business.create!(name: 'Test Business', timezone: 'America/New_York') }

  describe 'validations' do
    it 'is valid with valid attributes and a business' do
      user = User.new(email: 'valid@example.com', password: 'password123', business: business)
      expect(user).to be_valid
    end

    it 'is valid without a business (for signup flow)' do
      user = User.new(email: 'signup@example.com', password: 'password123', business: nil)
      expect(user).to be_valid
    end

    it 'is invalid without an email' do
      user = User.new(password: 'password123', business: business)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'is invalid without a password' do
      user = User.new(email: 'test@example.com', business: business)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it 'enforces unique email globally' do
      User.create!(email: 'unique@example.com', password: 'password123', business: business, role: :admin)
      duplicate_user = User.new(email: 'unique@example.com', password: 'password123', business: nil, role: :staff)

      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include("has already been taken")
    end
  end

  describe 'associations' do
    it 'belongs to a business' do
      association = User.reflect_on_association(:business)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'allows optional business' do
      association = User.reflect_on_association(:business)
      expect(association.options[:optional]).to be true
    end
  end

  describe 'roles' do
    it 'can be an admin' do
      user = User.create!(email: 'admin@example.com', password: 'password123', business: business, role: :admin)
      expect(user.admin?).to be true
      expect(user.staff?).to be false
    end

    it 'can be a staff member' do
      user = User.create!(email: 'staff@example.com', password: 'password123', business: business, role: :staff)
      expect(user.staff?).to be true
      expect(user.admin?).to be false
    end

    it 'defaults to admin role if not specified' do
      user = User.create!(email: 'default@example.com', password: 'password123', business: business)
      expect(user.admin?).to be true
    end
  end

  describe 'tenant scoping' do
    it 'is scoped to business tenant' do
      expect(User.ancestors).to include(ActsAsTenant::ModelExtensions)
    end
  end

  describe 'Devise modules' do
    it 'includes database_authenticatable' do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it 'includes registerable' do
      expect(User.devise_modules).to include(:registerable)
    end

    it 'has custom validation instead of validatable' do
      # We use custom validation instead of :validatable
      expect(User.devise_modules).not_to include(:validatable)
    end
  end
end
