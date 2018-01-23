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
  has_many :purchased_vehicles,
           -> { where(purchased: true) },
           class_name: 'Vehicle',
           inverse_of: false
  has_many :purchased_models,
           class_name: 'Model',
           through: :purchased_vehicles,
           source: :model,
           inverse_of: false
  has_many :pending_memberships,
           -> { where(approved: false) },
           class_name: 'FleetMembership',
           dependent: :destroy,
           inverse_of: false
  has_many :pending_fleets,
           through: :pending_memberships,
           source: :fleet
  has_many :memberships,
           -> { where(approved: true) },
           class_name: 'FleetMembership',
           dependent: :destroy,
           inverse_of: false
  has_many :fleets,
           through: :memberships
  has_many :admin_memberships,
           -> { where(admin: true, approved: true) },
           class_name: 'FleetMembership',
           inverse_of: false
  has_many :admin_fleets,
           through: :admin_memberships,
           source: :fleet

  validates :username, uniqueness: { case_sensitive: false }

  attr_accessor :login

  after_create :send_admin_mail
  before_save :update_gravatar_hash
  before_save :check_rsi_verification
  before_validation :clean_username
  before_validation :clean_rsi_handle

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    if login.present?
      where(conditions.to_h)
        .find_by(["lower(username) = :value OR lower(email) = :value", { value: login.downcase }])
    elsif conditions.key?(:username) || conditions.key?(:email)
      find_by(conditions.to_h)
    end
  end

  def send_admin_mail
    UserMailer.notify_admin(self).deliver_later
  end

  def update_gravatar_hash
    hash = if gravatar.blank?
             Digest::MD5.hexdigest(id.to_s)
           else
             Digest::MD5.hexdigest(gravatar.downcase.strip)
           end
    self.gravatar_hash = hash
  end

  def generate_rsi_verification_token
    return if rsi_verification_token.present?

    loop do
      verification_token = Devise.friendly_token
      next if User.find_by(id: id, rsi_verification_token: verification_token)
      self.rsi_verification_token = verification_token
      save
      break
    end
  end

  def check_rsi_verification
    return unless rsi_handle_changed?

    self.rsi_verified = false
  end

  def clean_username
    return if username.blank?
    self.username = username.strip
  end

  def clean_rsi_handle
    return if rsi_handle.blank?
    self.rsi_handle = rsi_handle.strip
  end

  def avatar(size = 24)
    "https://www.gravatar.com/avatar/#{gravatar_hash}?s=#{size}&d=https%3A%2F%2Fidenticons.github.com%2F#{gravatar_hash}.png&amp;r=x&amp;s=#{size}"
  end
end
