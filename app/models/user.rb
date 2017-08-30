# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :timeoutable,
         authentication_keys: [:login]

  has_many :user_ships
  has_many :ships, through: :user_ships

  validates :username, uniqueness: { case_sensitive: false }

  attr_accessor :login

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

  after_create :send_admin_mail

  def send_admin_mail
    UserMailer.notify_admin(self).deliver
  end

  before_save :extract_rsi_information
  before_save :update_gravatar_hash

  def update_gravatar_hash
    hash = if gravatar.blank?
             Digest::MD5.hexdigest(id.to_s)
           else
             Digest::MD5.hexdigest(gravatar.downcase.strip)
           end
    self.gravatar_hash = hash
  end

  def extract_rsi_information
    if rsi_profile_url.present?
      self.rsi_handle = rsi_profile_url.split("/").last
    end

    return if rsi_organization_url.blank?
    self.rsi_organization_handle = rsi_organization_url.split("/").last
  end

  def avatar(size = 24)
    "https://www.gravatar.com/avatar/#{gravatar_hash}?s=#{size}&d=https%3A%2F%2Fidenticons.github.com%2F#{gravatar_hash}.png&amp;r=x&amp;s=#{size}"
  end
end
