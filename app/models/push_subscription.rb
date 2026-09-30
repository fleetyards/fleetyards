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

  belongs_to :user

  # Endpoint plus keys is a capability: whoever holds them can push to that
  # device. Deterministic for the endpoint because the unique index and the
  # re-subscribe lookup both query by it.
  encrypts :endpoint, deterministic: true
  encrypts :p256dh_key, :auth_key

  validates :endpoint, :p256dh_key, :auth_key, presence: true
  validate :endpoint_is_a_push_service

  # A known endpoint is the same device subscribing again, possibly under a
  # different account after a second login on a shared browser, so it moves
  # rather than failing the unique index.
  def self.subscribe(user:, endpoint:, p256dh_key:, auth_key:, user_agent: nil)
    attempts ||= 0
    subscription = find_or_initialize_by(endpoint:)
    subscription.assign_attributes(
      user:,
      p256dh_key:,
      auth_key:,
      user_agent: user_agent&.truncate(USER_AGENT_MAX),
      failure_count: 0,
      last_failed_at: nil
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

  def self.prune_beyond_cap(user)
    keep = user.push_subscriptions.order(updated_at: :desc).limit(MAX_PER_USER).select(:id)

    user.push_subscriptions.where.not(id: keep).delete_all
  end

  private def endpoint_is_a_push_service
    return if endpoint.blank?

    uri = URI.parse(endpoint)
    host = uri.host.to_s.downcase

    return if uri.is_a?(URI::HTTPS) && PUSH_SERVICE_HOSTS.any? { |allowed| allowed.start_with?(".") ? host.end_with?(allowed) : host == allowed }

    errors.add(:endpoint, :invalid)
  rescue URI::InvalidURIError
    errors.add(:endpoint, :invalid)
  end
end
