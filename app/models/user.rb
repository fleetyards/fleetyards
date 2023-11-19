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
#  hangar_updated_at         :datetime
#  hide_owner                :boolean          default(FALSE), not null
#  homepage                  :string
#  last_active_at            :datetime
#  last_sign_in_at           :datetime
#  last_sign_in_ip           :string(255)
#  locale                    :string(255)
#  locked_at                 :datetime
#  normalized_email          :string
#  normalized_username       :string
#  otp_backup_codes          :string           is an Array
#  otp_required_for_login    :boolean
#  otp_secret                :string
#  public_hangar             :boolean          default(TRUE)
#  public_hangar_loaners     :boolean          default(FALSE)
#  public_wishlist           :boolean          default(FALSE)
#  purchased_vehicles_count  :integer          default(0), not null
#  remember_created_at       :datetime
#  reset_password_sent_at    :datetime
#  reset_password_token      :string(255)
#  rsi_handle                :string
#  sale_notify               :boolean          default(FALSE)
#  sign_in_count             :integer          default(0), not null
#  tester                    :boolean          default(FALSE)
#  tracking                  :boolean          default(TRUE)
#  twitch                    :string
#  unconfirmed_email         :string(255)
#  unlock_token              :string(255)
#  username                  :string(255)      default(""), not null
#  wanted_vehicles_count     :integer          default(0), not null
#  youtube                   :string
#  created_at                :datetime
#  updated_at                :datetime
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_normalized_username   (normalized_username)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#  index_users_on_username              (username) UNIQUE
#
class User < ApplicationRecord
  include UrlFieldHelper
  include Rails.application.routes.url_helpers

  devise :two_factor_authenticatable, :two_factor_backupable, :recoverable, :trackable,
    :validatable, :confirmable, :rememberable, :timeoutable,
    authentication_keys: [:login], otp_secret_encryption_key: Rails.application.credentials.devise_otp_secret!,
    otp_backup_code_length: 10, otp_number_of_backup_codes: 10

  has_many :vehicles, dependent: :destroy
  has_many :purchased_vehicles,
    -> { where(wanted: false) },
    class_name: "Vehicle",
    counter_cache: true,
    inverse_of: false
  has_many :wanted_vehicles,
    -> { where(wanted: true) },
    class_name: "Vehicle",
    counter_cache: true,
    inverse_of: false
  has_many :models,
    through: :vehicles
  has_many :vehicle_modules,
    through: :vehicles
  has_many :vehicle_upgrades,
    through: :vehicles
  has_many :manufacturers,
    through: :models
  has_many :public_vehicles,
    -> { where(wanted: false, public: true) },
    dependent: :destroy,
    class_name: "Vehicle",
    inverse_of: false
  has_many :public_models,
    class_name: "Model",
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
    uniqueness: {case_sensitive: false},
    format: {with: /\A[a-zA-Z0-9\-_]+\Z/}
  validates :email,
    uniqueness: {case_sensitive: false},
    presence: true

  attr_accessor :login

  before_validation :clean_username
  before_validation :set_normalized_login_fields
  before_validation :update_urls
  before_create :setup_otp_secret

  after_update :notify_user
  after_save :touch_fleet_memberships

  mount_uploader :avatar, AvatarUploader

  def self.ransackable_attributes(auth_object = nil)
    [
      "avatar", "confirmed_at", "created_at", "current_sign_in_at", "discord", "email",
      "guilded", "hangar_updated_at", "homepage", "last_active_at", "last_sign_in_at", "locale",
      "twitch", "updated_at", "username", "wanted_vehicles_count", "youtube"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    [
      "fleet_memberships", "fleets", "manufacturers", "models", "public_models", "public_vehicles",
      "purchased_vehicles", "vehicle_modules", "vehicle_upgrades", "vehicles", "wanted_vehicles"
    ]
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    if login.present?
      where(conditions.to_h)
        .find_by(["normalized_username = :value OR normalized_email = :value", {value: login.downcase}])
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

  def set_normalized_login_fields
    self.normalized_email = email.downcase
    self.normalized_username = username.downcase
  end

  def update_urls(force: false)
    %i[discord twitch youtube homepage guilded].each do |field|
      send("#{field}=", ensure_valid_url(self, field, force:))
    end
  end

  def setup_otp_secret
    self.otp_secret = User.generate_otp_secret
  end

  def send_devise_notification(notification, *)
    devise_mailer.send(notification, self, *).deliver_later
  end

  def public_hangar_url
    return short_public_hangar_url(username:) if Rails.configuration.app.short_domain.present?

    frontend_public_hangar_url(username:)
  end

  def public_wishlist_url
    return short_public_wishlist_url(username:) if Rails.configuration.app.short_domain.present?

    frontend_public_wishlist_url(username:)
  end

  def resend_confirmation
    return if confirmed?

    return if confirmation_sent_at.present? && confirmation_sent_at > (10.minutes.ago)

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

  def features
    Flipper.features.filter_map do |feature|
      Flipper.enabled?(feature.name, self) ? feature.name : nil
    end
  end

  def reset_otp
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:otp_required_for_login, false)
    update_column(:encrypted_otp_secret, nil)
    update_column(:encrypted_otp_secret_iv, nil)
    update_column(:encrypted_otp_secret_salt, nil)
    update_column(:otp_backup_codes, nil)
    update_column(:otp_secret, nil)
    # rubocop:enable Rails/SkipsModelValidations
    update(otp_secret: User.generate_otp_secret)
  end

  ## TODO: remove once Deivse Two Factor upgrade to 5.x is done
  # Decrypt and return the `encrypted_otp_secret` attribute which was used in
  # prior versions of devise-two-factor
  # @return [String] The decrypted OTP secret
  private def legacy_otp_secret
    return nil unless self[:encrypted_otp_secret]
    return nil unless self.class.otp_secret_encryption_key

    hmac_iterations = 2000 # a default set by the Encryptor gem
    key = self.class.otp_secret_encryption_key
    salt = Base64.decode64(encrypted_otp_secret_salt)
    iv = Base64.decode64(encrypted_otp_secret_iv)

    raw_cipher_text = Base64.decode64(encrypted_otp_secret)
    # The last 16 bytes of the ciphertext are the authentication tag - we use
    # Galois Counter Mode which is an authenticated encryption mode
    cipher_text = raw_cipher_text[0..-17]
    auth_tag = raw_cipher_text[-16..]

    # this alrorithm lifted from
    # https://github.com/attr-encrypted/encryptor/blob/master/lib/encryptor.rb#L54

    # create an OpenSSL object which will decrypt the AES cipher with 256 bit
    # keys in Galois Counter Mode (GCM). See
    # https://ruby.github.io/openssl/OpenSSL/Cipher.html
    cipher = OpenSSL::Cipher.new("aes-256-gcm")

    # tell the cipher we want to decrypt. Symmetric algorithms use a very
    # similar process for encryption and decryption, hence the same object can
    # do both.
    cipher.decrypt

    # Use a Password-Based Key Derivation Function to generate the key actually
    # used for encryptoin from the key we got as input.
    cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(key, salt, hmac_iterations, cipher.key_len)

    # set the Initialization Vector (IV)
    cipher.iv = iv

    # The tag must be set after calling Cipher#decrypt, Cipher#key= and
    # Cipher#iv=, but before calling Cipher#final. After all decryption is
    # performed, the tag is verified automatically in the call to Cipher#final.
    #
    # If the auth_tag does not verify, then #final will raise OpenSSL::Cipher::CipherError
    cipher.auth_tag = auth_tag

    # auth_data must be set after auth_tag has been set when decrypting See
    # http://ruby-doc.org/stdlib-2.0.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html#method-i-auth_data-3D
    # we are not adding any authenticated data but OpenSSL docs say this should
    # still be called.
    cipher.auth_data = ""

    # #update is (somewhat confusingly named) the method which actually
    # performs the decryption on the given chunk of data. Our OTP secret is
    # short so we only need to call it once.
    #
    # It is very important that we call #final because:
    #
    # 1. The authentication tag is checked during the call to #final
    # 2. Block based cipher modes (e.g. CBC) work on fixed size chunks. We need
    #    to call #final to get it to process the last chunk properly. The output
    #    of #final should be appended to the decrypted value. This isn't
    #    required for streaming cipher modes but including it is a best practice
    #    so that your code will continue to function correctly even if you later
    #    change to a block cipher mode.
    cipher.update(cipher_text) + cipher.final
  end
end
