# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20261013140000_retire_x_announcement_deliveries.rb")

class RetireXAnnouncementDeliveriesTest < ActiveSupport::TestCase
  def retire
    RetireXAnnouncementDeliveries.new.up
  end

  # The enum no longer names X, so neither the column nor the row can be
  # written through the model.
  def x_only(status, **attributes)
    announcement = create(:announcement, notify_users: false, post_discord: true, **attributes)
    Announcement.connection.execute(<<~SQL.squish)
      UPDATE announcements
      SET status = '#{status}', post_x = TRUE, post_discord = FALSE
      WHERE id = '#{announcement.id}'
    SQL
    announcement
  end

  def x_delivery(announcement)
    AnnouncementDelivery.connection.execute(<<~SQL.squish)
      INSERT INTO announcement_deliveries (announcement_id, channel, status, created_at, updated_at)
      VALUES ('#{announcement.id}', 'x', 'failed', NOW(), NOW())
    SQL
  end

  test "deletes the X deliveries and keeps the others" do
    announcement = create(:announcement, :social, :published)
    bluesky = create(:announcement_delivery, announcement:, channel: "bluesky")
    x_delivery(announcement)

    retire

    assert_equal [bluesky.id], AnnouncementDelivery.where(announcement:).pluck(:id)
  end

  test "sends a scheduled or failed announcement that only went to X back to draft" do
    scheduled = x_only("scheduled", publish_at: 1.day.from_now)
    failed = x_only("failed")

    retire

    assert scheduled.reload.status_draft?
    assert failed.reload.status_draft?
  end

  test "leaves an announcement that still has another channel alone" do
    announcement = create(:announcement, :social, status: "scheduled", publish_at: 1.day.from_now)

    retire

    assert announcement.reload.status_scheduled?
  end
end
