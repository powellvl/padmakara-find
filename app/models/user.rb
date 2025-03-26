class User < ApplicationRecord
  enum :role, {
    user: "user",
    admin: "admin"
  }
  after_initialize :set_default_role, if: :new_record?

  def set_default_role
    self.role ||= :user
  end

  validates :email, presence: true, uniqueness: true
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email, with: ->(e) { e.strip.downcase }
end
