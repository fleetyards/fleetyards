# frozen_string_literal: true

require "test_helper"

class AnnouncementDeliveryTest < ActiveSupport::TestCase
  setup do
    @announcement = create(:announcement)
  end

  test "one row per channel per announcement" do
    create(:announcement_delivery, announcement: @announcement, channel: "discord")

    duplicate = build(:announcement_delivery, announcement: @announcement, channel: "discord")

    refute duplicate.valid?
  end

  test "#succeed! records the external id and clears an earlier error" do
    delivery = create(:announcement_delivery, announcement: @announcement, status: "failed", error: "boom")

    delivery.succeed!(external_id: "at://post/1")

    assert delivery.status_succeeded?
    assert_equal "at://post/1", delivery.external_id
    assert_nil delivery.error
    assert delivery.delivered_at.present?
  end

  test "#fail! keeps the message and leaves delivered_at unset" do
    delivery = create(:announcement_delivery, announcement: @announcement)

    delivery.fail!("rate limited")

    assert delivery.status_failed?
    assert_equal "rate limited", delivery.error
    assert_nil delivery.delivered_at
  end

  test "#skip! is distinct from a failure" do
    delivery = create(:announcement_delivery, announcement: @announcement)

    delivery.skip!("not configured")

    assert delivery.status_skipped?
    refute delivery.status_failed?
  end
end
