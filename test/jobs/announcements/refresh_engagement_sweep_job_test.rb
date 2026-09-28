# frozen_string_literal: true

require "test_helper"

module Announcements
  class RefreshEngagementSweepJobTest < ActiveJob::TestCase
    test "#perform queues only the deliveries whose counts are due" do
      ::Discord::Engagement.stubs(:configured?).returns(true)
      announcement = create(:announcement, :social, :published)
      due = create(:announcement_delivery, announcement:, channel: "bluesky", status: "succeeded", delivered_at: 1.hour.ago)
      create(
        :announcement_delivery,
        announcement:, channel: "discord", status: "succeeded", delivered_at: 1.hour.ago, engagement_fetched_at: 10.minutes.ago,
        posted_parts: [{"index" => 0, "message_id" => "m", "channel_id" => "c"}]
      )
      create(:announcement_delivery, announcement:, channel: "x", status: "succeeded", delivered_at: 1.hour.ago)
      create(:announcement_delivery, announcement: create(:announcement, :social, :published), channel: "bluesky", status: "succeeded", delivered_at: 31.days.ago)

      queued = []
      Announcements::RefreshEngagementJob.stubs(:perform_async).with { |id| queued << id }

      Announcements::RefreshEngagementSweepJob.new.perform

      assert_equal [due.id], queued
    end
  end
end
