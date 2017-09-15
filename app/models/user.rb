# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :timeoutable,
         authentication_keys: [:login]

  has_many :user_ships
  has_many :ships, through: :user_ships
  has_many :rsi_affiliations
  has_many :rsi_orgs, through: :rsi_affiliations

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
  after_save :fetch_rsi_orgs

  def send_admin_mail
    UserMailer.notify_admin(self).deliver_later
  end

  def fetch_rsi_orgs
    return if rsi_handle.blank?
    Rails.logger.debug 'after_save'.to_yaml
    UserRsiOrgsWorker.perform_async(id)
  end

  before_save :update_gravatar_hash
  before_validation :clean_username
  before_validation :clean_rsi_handle

  def update_gravatar_hash
    hash = if gravatar.blank?
             Digest::MD5.hexdigest(id.to_s)
           else
             Digest::MD5.hexdigest(gravatar.downcase.strip)
           end
    self.gravatar_hash = hash
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
