# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :timeoutable,
         authentication_keys: [:login]

  has_many :vehicles,
           dependent: :destroy
  has_many :models,
           through: :vehicles
  has_many :manufacturers,
           through: :models
  has_many :public_vehicles,
           -> { where(purchased: true, public: true) },
           class_name: 'Vehicle',
           inverse_of: false
  has_many :public_models,
           class_name: 'Model',
           through: :public_vehicles,
           source: :model,
           inverse_of: false
  has_many :fleet_memberships,
           -> { order(primary: :desc) },
           dependent: :destroy,
           inverse_of: false
  has_many :fleets,
           through: :fleet_memberships

  validates :username,
            uniqueness: { case_sensitive: false },
            format: { with: /\A[a-zA-Z0-9\-_]+\Z/ }
  validates :email,
            uniqueness: { case_sensitive: false },
            presence: true

  attr_accessor :login

  before_validation :clean_username

  mount_uploader :avatar, AvatarUploader

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    if login.present?
      where(conditions.to_h)
        .find_by(['lower(username) = :value OR lower(email) = :value', { value: login.downcase }])
    elsif conditions.key?(:username) || conditions.key?(:email)
      find_by(conditions.to_h)
    end
  end

  def clean_username
    return if username.blank?

    self.username = username.strip
  end
end
