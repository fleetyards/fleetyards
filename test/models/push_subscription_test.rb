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
  setup do
    @user = create(:user)
  end

  def subscribe(user: @user, endpoint: "https://fcm.googleapis.com/fcm/send/abc", **attrs)
    PushSubscription.subscribe(user:, endpoint:, p256dh_key: "p256dh", auth_key: "auth", **attrs)
  end

  test "subscribing creates a row for the user" do
    subscription = subscribe

    assert subscription.persisted?
    assert_equal [subscription], @user.push_subscriptions.to_a
  end

  test "subscribing again with a known endpoint updates the row instead of adding one" do
    first = subscribe
    first.update_columns(failure_count: 3, last_failed_at: 1.day.ago)

    second = subscribe(auth_key: "rotated")

    assert_equal first.id, second.id
    assert_equal 1, PushSubscription.count
    assert_equal "rotated", second.reload.auth_key
    assert_equal 0, second.failure_count
    assert_nil second.last_failed_at
  end

  # A shared browser, a second login: the device now belongs to whoever
  # subscribed it last.
  test "a known endpoint subscribed by another user moves to that user" do
    subscribe
    other = create(:user)

    subscribe(user: other)

    assert_empty @user.push_subscriptions.reload
    assert_equal 1, other.push_subscriptions.count
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
    refute_equal "p256dh", row["p256dh_key"]
    refute_equal "auth", row["auth_key"]
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
