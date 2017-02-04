# frozen_string_literal: true
class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :confirmable, :lockable, :timeoutable,
         authentication_keys: [:login], omniauth_providers: [:github, :facebook, :twitter, :google_oauth2]

  has_many :user_ships
  has_many :ships, through: :user_ships

  validates :username, uniqueness: { case_sensitive: false }

  attr_accessor :login

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value", { value: login.downcase }]).first
    elsif conditions.key?(:username) || conditions.key?(:email)
      where(conditions.to_h).first
    end
  end

  def self.from_omniauth(data)
    user = User.find_by(email: data[:email])
    if user && user.confirmed?
      user.provider = data[:provider]
      user.uid = data[:uid]
      return user
    end

    where(data.slice(:provider, :uid)).first_or_create do |user|
      user.email = data[:email]
      user.gravatar = data[:email]
      user.password = Devise.friendly_token[0, 32]
      user.username = data[:username]
      user.skip_confirmation!
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.oauth_data"]
        user.email = data[:email] if user.email.blank?
        user.username = data[:username] if user.username.blank?
      end
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

    if rsi_organization_url.present?
      self.rsi_organization_handle = rsi_organization_url.split("/").last
    end
  end
end
