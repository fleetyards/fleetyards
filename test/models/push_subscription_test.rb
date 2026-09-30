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
require "test_helper"

class PushSubscriptionTest < ActiveSupport::TestCase
  P256DH = "BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM"
  AUTH = "tBHItJI5svbpez7KI4CCXg"
  OTHER_AUTH = Base64.urlsafe_encode64("0123456789abcdef", padding: false)

  setup do
    @user = create(:user)
  end

  def subscribe(user: @user, endpoint: "https://fcm.googleapis.com/fcm/send/abc", p256dh_key: P256DH, auth_key: AUTH, **attrs)
    PushSubscription.subscribe(user:, endpoint:, p256dh_key:, auth_key:, **attrs)
  end

  test "subscribing creates a row for the user" do
    subscription = subscribe

    assert subscription.persisted?
    assert_equal [subscription], @user.push_subscriptions.to_a
  end

  test "subscribing again with a known endpoint updates the row instead of adding one" do
    first = subscribe
    first.update_columns(failure_count: 3, last_failed_at: 1.day.ago)

    second = subscribe(auth_key: OTHER_AUTH)

    assert_equal first.id, second.id
    assert_equal 1, PushSubscription.count
    assert_equal OTHER_AUTH, second.reload.auth_key
    assert_equal 0, second.failure_count
    assert_nil second.last_failed_at
  end

  # A shared browser, a second login: the device now belongs to whoever
  # subscribed it last.
  test "a known endpoint subscribed by another user with the same keys moves to that user" do
    subscribe
    other = create(:user)

    subscribe(user: other)

    assert_empty @user.push_subscriptions.reload
    assert_equal 1, other.push_subscriptions.count
  end

  # Knowing an endpoint is not holding the subscription: without its auth
  # secret nobody can take the device away from its owner.
  test "another user without the keys cannot take a known endpoint" do
    subscribe
    other = create(:user)

    subscription = subscribe(user: other, auth_key: OTHER_AUTH)

    assert subscription.errors.added?(:endpoint, :taken)
    assert_equal 1, @user.push_subscriptions.count
    assert_equal AUTH, @user.push_subscriptions.sole.auth_key
    assert_empty other.push_subscriptions
  end

  test "the same keys with different padding still move the browser" do
    subscribe
    other = create(:user)

    subscribe(user: other, auth_key: "#{AUTH}==")

    assert_equal 1, other.push_subscriptions.count
  end

  test "stores keys without padding" do
    assert_equal AUTH, subscribe(auth_key: "#{AUTH}==").reload.auth_key
  end

  test "rejects a public key that is not on the P-256 curve" do
    off_curve = Base64.urlsafe_encode64("\x04".b + ("\x00".b * 64), padding: false)

    subscription = subscribe(p256dh_key: off_curve)

    refute subscription.persisted?
    assert subscription.errors.added?(:p256dh_key, :invalid)
  end

  test "re-subscribing with nothing changed still counts as recent for the cap" do
    subscription = subscribe
    subscription.update_columns(updated_at: 1.year.ago)

    subscribe

    assert_operator subscription.reload.updated_at, :>, 1.minute.ago
  end

  test "rejects keys that are not an RFC 8291 key pair" do
    subscription = subscribe(p256dh_key: "not-a-key", auth_key: Base64.urlsafe_encode64("short", padding: false))

    refute subscription.persisted?
    assert subscription.errors.added?(:p256dh_key, :invalid)
    assert subscription.errors.added?(:auth_key, :invalid)
  end

  test "keeps only the newest subscriptions past the per-user cap" do
    oldest = create(:push_subscription, user: @user, updated_at: 1.year.ago)
    create_list(:push_subscription, PushSubscription::MAX_PER_USER - 1, user: @user, updated_at: 1.day.ago)

    subscribe

    assert_equal PushSubscription::MAX_PER_USER, @user.push_subscriptions.count
    refute PushSubscription.exists?(oldest.id)
  end

  test "the cap does not touch another user's subscriptions" do
    other = create(:push_subscription, updated_at: 1.year.ago)
    create_list(:push_subscription, PushSubscription::MAX_PER_USER, user: @user)

    subscribe

    assert PushSubscription.exists?(other.id)
    assert_equal PushSubscription::MAX_PER_USER, @user.push_subscriptions.count
  end

  %w[
    https://fcm.googleapis.com/fcm/send/abc
    https://updates.push.services.mozilla.com/wpush/v2/abc
    https://web.push.apple.com/abc
    https://wns2-par02p.notify.windows.com/w/?token=abc
  ].each do |endpoint|
    test "accepts a push service endpoint #{URI.parse(endpoint).host}" do
      assert build(:push_subscription, endpoint:).valid?
    end
  end

  # The server POSTs to the endpoint, so anything else is a request forgery
  # waiting to happen.
  %w[
    http://fcm.googleapis.com/fcm/send/abc
    https://169.254.169.254/latest/meta-data
    https://localhost:3000/api
    https://evil.example/fcm.googleapis.com
    https://fcm.googleapis.com.evil.example/abc
    https://notapush.apple.com/abc
    not-a-url
  ].each do |endpoint|
    test "rejects #{endpoint}" do
      subscription = build(:push_subscription, endpoint:)

      refute subscription.valid?
      assert subscription.errors.added?(:endpoint, :invalid)
    end
  end

  test "an invalid endpoint is not saved and prunes nothing" do
    existing = create_list(:push_subscription, PushSubscription::MAX_PER_USER, user: @user)

    subscription = subscribe(endpoint: "https://169.254.169.254/")

    refute subscription.persisted?
    assert_equal existing.map(&:id).sort, @user.push_subscriptions.pluck(:id).sort
  end

  test "stores the endpoint and keys encrypted" do
    subscription = subscribe

    row = PushSubscription.connection.select_one(
      "SELECT endpoint, p256dh_key, auth_key FROM push_subscriptions WHERE id = #{PushSubscription.connection.quote(subscription.id)}"
    )

    refute_includes row["endpoint"], "fcm.googleapis.com"
    refute_equal P256DH, row["p256dh_key"]
    refute_equal AUTH, row["auth_key"]
    assert_equal "https://fcm.googleapis.com/fcm/send/abc", subscription.reload.endpoint
  end

  test "truncates a long user agent" do
    subscription = subscribe(user_agent: "a" * 1000)

    assert_equal PushSubscription::USER_AGENT_MAX, subscription.user_agent.length
  end

  test "deleting the user deletes their subscriptions" do
    subscribe

    @user.destroy!

    assert_equal 0, PushSubscription.count
  end
end
