# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: announcement_deliveries
#
#  id              :uuid             not null, primary key
#  attempts        :integer          default(0), not null
#  channel         :string           not null
#  delivered_at    :datetime
#  error           :text
#  posted_parts    :jsonb            not null
#  status          :string           default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  announcement_id :uuid             not null
#  external_id     :string
#
# Indexes
#
#  index_announcement_deliveries_on_announcement_id_and_channel  (announcement_id,channel) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (announcement_id => announcements.id) ON DELETE => cascade
#
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

  # The fan-out is idempotent, so re-running one costs nothing and is the way
  # out of a delivery that stopped short. Re-posting a thread is not.
  test "a pending in-app delivery is retryable and a pending social one is not" do
    in_app = create(:announcement_delivery, announcement: @announcement, channel: "in_app", status: "pending")
    social = create(:announcement_delivery, announcement: @announcement, channel: "x", status: "pending")

    assert in_app.retryable?
    refute social.retryable?
    assert_includes in_app.claimable_statuses, "pending"
    refute_includes social.claimable_statuses, "pending"
  end

  test "#skip! is distinct from a failure" do
    delivery = create(:announcement_delivery, announcement: @announcement)

    delivery.skip!("not configured")

    assert delivery.status_skipped?
    refute delivery.status_failed?
  end
end
