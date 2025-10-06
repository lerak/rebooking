class User < ApplicationRecord
  acts_as_tenant(:business)

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # Note: removed :validatable to add custom email validation scoped by business
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable

  belongs_to :business

  enum :role, { admin: 0, staff: 1 }

  # Custom validations (since we removed :validatable)
  validates :email, presence: true, uniqueness: { scope: :business_id, case_sensitive: false }
  validates :email, format: { with: Devise.email_regexp }, allow_blank: true
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  validates :password, confirmation: true, if: :password_required?

  private

  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end
end
