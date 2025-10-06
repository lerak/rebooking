require 'rails_helper'

RSpec.describe User, type: :model do
  let(:business) { Business.create!(name: 'Test Business', timezone: 'America/New_York') }

  describe 'validations' do
    it 'is valid with valid attributes' do
      user = User.new(email: 'test@example.com', password: 'password123', business: business)
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

    it 'is invalid without a business' do
      user = User.new(email: 'test@example.com', password: 'password123')
      expect(user).not_to be_valid
      expect(user.errors[:business]).to include("must exist")
    end

    it 'enforces unique email per business' do
      User.create!(email: 'test@example.com', password: 'password123', business: business, role: :admin)
      duplicate_user = User.new(email: 'test@example.com', password: 'password123', business: business, role: :staff)

      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include("has already been taken")
    end

    it 'allows same email across different businesses' do
      business2 = Business.create!(name: 'Another Business', timezone: 'America/Los_Angeles')

      ActsAsTenant.without_tenant do
        user1 = User.create!(email: 'test@example.com', password: 'password123', business: business, role: :admin)
        user2 = User.new(email: 'test@example.com', password: 'password123', business: business2, role: :admin)

        expect(user2).to be_valid
      end
    end
  end

  describe 'associations' do
    it 'belongs to a business' do
      association = User.reflect_on_association(:business)
      expect(association.macro).to eq(:belongs_to)
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
      # We use custom validation scoped by business instead of :validatable
      expect(User.devise_modules).not_to include(:validatable)
    end
  end
end
