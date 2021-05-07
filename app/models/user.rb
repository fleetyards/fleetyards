# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                        :uuid             not null, primary key
#  avatar                    :string
#  confirmation_sent_at      :datetime
#  confirmation_token        :string(255)
#  confirmed_at              :datetime
#  consumed_timestep         :integer
#  current_sign_in_at        :datetime
#  current_sign_in_ip        :string(255)
#  discord                   :string
#  email                     :string(255)      default(""), not null
#  encrypted_otp_secret      :string
#  encrypted_otp_secret_iv   :string
#  encrypted_otp_secret_salt :string
#  encrypted_password        :string(255)      default(""), not null
#  failed_attempts           :integer          default(0), not null
#  guilded                   :string
#  homepage                  :string
#  last_sign_in_at           :datetime
#  last_sign_in_ip           :string(255)
#  locale                    :string(255)
#  locked_at                 :datetime
#  otp_backup_codes          :string           is an Array
#  otp_required_for_login    :boolean
#  public_hangar             :boolean          default(TRUE)
#  remember_created_at       :datetime
#  reset_password_sent_at    :datetime
#  reset_password_token      :string(255)
#  rsi_handle                :string
#  sale_notify               :boolean          default(FALSE)
#  sign_in_count             :integer          default(0), not null
#  tracking                  :boolean          default(TRUE)
#  twitch                    :string
#  unconfirmed_email         :string(255)
#  unlock_token              :string(255)
#  username                  :string(255)      default(""), not null
#  youtube                   :string
#  created_at                :datetime
#  updated_at                :datetime
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#  index_users_on_username              (username) UNIQUE
#
class User < ApplicationRecord
  include UrlFieldHelper
  include Rails.application.routes.url_helpers

  devise :two_factor_authenticatable, :two_factor_backupable, :database_authenticatable,
         :recoverable, :trackable, :validatable, :confirmable, :rememberable, :timeoutable,
         authentication_keys: [:login], otp_secret_encryption_key: Rails.application.credentials.devise_otp_secret!,
         otp_backup_code_length: 10, otp_number_of_backup_codes: 10

  has_many :vehicles, dependent: :destroy
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

  before_validation :update_urls
  before_create :setup_otp_secret
  after_update :notify_user
  after_save :touch_fleet_memberships

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

  def self.confirmed
    where.not(confirmed_at: nil)
  end

  def self.unconfirmed
    where(confirmed_at: nil)
  end

  def update_urls(force: false)
    %i[discord twitch youtube homepage guilded].each do |field|
      send("#{field}=", ensure_valid_url(self, field, force: force))
    end
  end

  def setup_otp_secret
    self.otp_secret = User.generate_otp_secret
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def public_hangar_url
    return short_public_hangar_url(username: username) if Rails.configuration.fltyrd.short_domain.present?

    frontend_public_hangar_url(username: username)
  end

  def resend_confirmation
    return if confirmed?

    return if confirmation_sent_at.present? && confirmation_sent_at > (Time.zone.now - 10.minutes)

    send_confirmation_instructions
  end

  def clean_username
    return if username.blank?

    self.username = username.strip
  end

  def confirm_access_token
    Digest::MD5.hexdigest(Digest::MD5.hexdigest(Rails.application.credentials.confirm_access_secret!) + Digest::MD5.hexdigest(id))
  end

  private def touch_fleet_memberships
    # rubocop:disable Rails/SkipsModelValidations
    fleet_memberships.update_all(updated_at: Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end

  private def notify_user
    notify_two_factor_change if saved_change_to_otp_required_for_login?

    UserMailer.username_changed(email, username).deliver_later if saved_change_to_username?
  end

  private def notify_two_factor_change
    if otp_required_for_login?
      TwoFactorMailer.enabled(email, username).deliver_later
    else
      TwoFactorMailer.disabled(email, username).deliver_later
    end
  end

  # TODO: Remove once run on production
  def cleanup_profile_fields
    %i[twitch discord rsi_handle youtube homepage].each do |field|
      value = send(field)
      next if value != '' && value != 'null'

      update(field => nil)
    end
  end

  # override devise trackable to not save on every single request
  def update_tracked_fields!(request)
    # We have to check if the user is already persisted before running
    # `save` here because invalid users can be saved if we don't.
    # See https://github.com/heartcombo/devise/issues/4673 for more details.
    return if new_record?

    return if updated_at < Time.zone.now + 1.minute

    update_tracked_fields(request)
    save(validate: false)
  end
end
