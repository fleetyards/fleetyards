# frozen_string_literal: true

require "test_helper"

module Cleanup
  class PushSubscriptionsJobTest < ActiveJob::TestCase
    def stale_for(age)
      create(:push_subscription).tap { |subscription| subscription.update_columns(updated_at: age.ago) }
    end

    test "#perform deletes a subscription nothing reached or renewed for half a year" do
      stale = stale_for(PushSubscription::STALE_AFTER + 1.day)

      ::Cleanup::PushSubscriptionsJob.new.perform

      refute PushSubscription.exists?(stale.id)
    end

    test "#perform keeps one that was delivered to recently" do
      delivered = stale_for(PushSubscription::STALE_AFTER + 1.day)
      delivered.update_columns(last_delivered_at: 1.week.ago)

      ::Cleanup::PushSubscriptionsJob.new.perform

      assert PushSubscription.exists?(delivered.id)
    end

    # The settings page re-announces a subscribed browser on every visit.
    test "#perform keeps one whose browser re-subscribed recently" do
      renewed = stale_for(1.week)
      renewed.update_columns(last_delivered_at: 1.year.ago)

      ::Cleanup::PushSubscriptionsJob.new.perform

      assert PushSubscription.exists?(renewed.id)
    end

    # A signed-in visit touches the browser's row, which is what the app does
    # for a subscribed browser on every load.
    test "#perform keeps a browser that visits but was never pushed to" do
      subscription = stale_for(PushSubscription::STALE_AFTER + 1.day)

      subscription.touch
      ::Cleanup::PushSubscriptionsJob.new.perform

      assert PushSubscription.exists?(subscription.id)
      assert_nil subscription.reload.last_delivered_at
    end

    test "is scheduled" do
      schedule = YAML.safe_load(ERB.new(Rails.root.join("config/sidekiq_schedule.yml").read).result)

      assert_equal "Cleanup::PushSubscriptionsJob", schedule.dig("cleanup_push_subscriptions_job", "class")
    end
  end
end
