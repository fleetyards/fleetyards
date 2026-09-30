# frozen_string_literal: true

# == Schema Information
#
# Table name: push_subscriptions
#
#  id                :uuid             not null, primary key
#  auth_key          :string           not null
#  endpoint          :string           not null
#  failure_count     :integer          default(0), not null
#  last_delivered_at :datetime
#  last_failed_at    :datetime
#  p256dh_key        :string           not null
#  user_agent        :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :uuid             not null
#
# Indexes
#
#  index_push_subscriptions_on_endpoint  (endpoint) UNIQUE
#  index_push_subscriptions_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class PushSubscription < ApplicationRecord
  # A browser profile per device is plenty; past that the oldest are dead
  # endpoints from cleared site data.
  MAX_PER_USER = 10

  # The server POSTs to whatever endpoint a browser hands over, so an arbitrary
  # URL would let anyone aim it at an internal address.
  PUSH_SERVICE_HOSTS = [
    "fcm.googleapis.com",
    "updates.push.services.mozilla.com",
    ".push.apple.com",
    ".notify.windows.com"
  ].freeze

  USER_AGENT_MAX = 255

  # RFC 8291: an uncompressed P-256 point and a 16-byte secret. Anything else
  # cannot be encrypted to, so it is not a subscription.
  P256DH_BYTES = 65
  AUTH_BYTES = 16
  P256_GROUP = OpenSSL::PKey::EC::Group.new("prime256v1")

  # Neither delivered to nor re-subscribed for this long: the browser is gone,
  # or its owner stopped visiting. A browser that still has the site open
  # re-announces itself on every visit, which bumps `updated_at`.
  STALE_AFTER = 180.days

  belongs_to :user

  scope :stale, -> { where("GREATEST(last_delivered_at, updated_at) < ?", STALE_AFTER.ago) }

  # Endpoint plus keys is a capability: whoever holds them can push to that
  # device. Deterministic for the endpoint because the unique index and the
  # re-subscribe lookup both query by it.
  encrypts :endpoint, deterministic: true
  encrypts :p256dh_key, :auth_key

  # Browsers differ on base64url padding; one spelling per key is what lets
  # the same browser be recognised under a second account.
  normalizes :p256dh_key, :auth_key, with: ->(key) { canonical_key(key) }

  validates :endpoint, :p256dh_key, :auth_key, presence: true
  validate :endpoint_is_a_push_service
  validate :keys_are_well_formed

  # A known endpoint is the same device subscribing again, so it updates the
  # row rather than failing the unique index. It moves to another account only
  # with the same keys -- a second login on a shared browser sends them, while
  # someone who merely learned the endpoint does not have the auth secret.
  #
  # Always stamps `updated_at`, even when nothing else changed: the cap keeps
  # the most recently subscribed devices.
  def self.subscribe(user:, endpoint:, p256dh_key:, auth_key:, user_agent: nil)
    attempts ||= 0
    subscription = find_or_initialize_by(endpoint:)

    if subscription.persisted? && subscription.user_id != user.id &&
        !(subscription.p256dh_key == normalize_value_for(:p256dh_key, p256dh_key) &&
          subscription.auth_key == normalize_value_for(:auth_key, auth_key))
      subscription.errors.add(:endpoint, :taken)
      return subscription
    end

    subscription.assign_attributes(
      user:,
      p256dh_key:,
      auth_key:,
      user_agent: user_agent&.truncate(USER_AGENT_MAX),
      failure_count: 0,
      last_failed_at: nil,
      updated_at: Time.current
    )

    if subscription.save
      prune_beyond_cap(user)
    end

    subscription
  # Two tabs of one browser subscribing at once race to insert the same
  # endpoint; the loser finds the winner's row on the second pass.
  rescue ActiveRecord::RecordNotUnique
    attempts += 1
    retry if attempts < 2
    raise
  end

  # Names the keys a push went out with without carrying them into the job
  # queue, where they would sit unencrypted.
  def key_digest
    Digest::SHA256.hexdigest("#{p256dh_key}:#{auth_key}")
  end

  def self.prune_beyond_cap(user)
    keep = user.push_subscriptions.order(updated_at: :desc).limit(MAX_PER_USER).select(:id)

    user.push_subscriptions.where.not(id: keep).delete_all
  end

  private def endpoint_is_a_push_service
    return if endpoint.blank?

    uri = URI.parse(endpoint)
    host = uri.host.to_s.downcase

    return if uri.is_a?(URI::HTTPS) && uri.port == URI::HTTPS::DEFAULT_PORT && uri.userinfo.nil? &&
      PUSH_SERVICE_HOSTS.any? { |allowed| allowed.start_with?(".") ? host.end_with?(allowed) : host == allowed }

    errors.add(:endpoint, :invalid)
  rescue URI::InvalidURIError
    errors.add(:endpoint, :invalid)
  end

  def self.canonical_key(key)
    decoded = decode_key(key)
    decoded ? Base64.urlsafe_encode64(decoded, padding: false) : key
  end

  def self.decode_key(value)
    Base64.urlsafe_decode64(value.to_s)
  rescue ArgumentError
    nil
  end

  private def keys_are_well_formed
    errors.add(:p256dh_key, :invalid) if p256dh_key.present? && !p256_point?(self.class.decode_key(p256dh_key))

    auth = self.class.decode_key(auth_key)
    errors.add(:auth_key, :invalid) if auth_key.present? && auth&.bytesize != AUTH_BYTES
  end

  # Uncompressed (0x04) and on the curve. OpenSSL also parses the hybrid 0x06
  # and 0x07 forms, which Web Push does not accept; and the right length and
  # prefix alone are not enough, since a point off the curve cannot be
  # encrypted to at all.
  private def p256_point?(bytes)
    return false unless bytes&.bytesize == P256DH_BYTES && bytes.getbyte(0) == 0x04

    OpenSSL::PKey::EC::Point.new(P256_GROUP, OpenSSL::BN.new(bytes, 2)).on_curve?
  rescue OpenSSL::PKey::EC::Point::Error
    false
  end
end
