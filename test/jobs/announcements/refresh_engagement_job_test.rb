# frozen_string_literal: true

require "test_helper"
require "bsky/engagement"
require "discord/engagement"

module Announcements
  class RefreshEngagementJobTest < ActiveJob::TestCase
    setup do
      @announcement = create(:announcement, :social, :published)
    end

    test "#perform stores a Bluesky thread's counts" do
      delivery = create(
        :announcement_delivery,
        announcement: @announcement, channel: "bluesky", status: "succeeded", delivered_at: 1.hour.ago,
        posted_parts: [{"uri" => "at://1", "cid" => "a"}, {"uri" => "at://2", "cid" => "b"}]
      )
      counts = {"likes" => 3, "reposts" => 1, "replies" => 0, "quotes" => 0}
      ::Bsky::Engagement.any_instance.expects(:fetch).with(["at://1", "at://2"]).returns(counts)

      freeze_time do
        Announcements::RefreshEngagementJob.new.perform(delivery.id)

        delivery.reload
        assert_equal counts, delivery.engagement
        assert_equal Time.current, delivery.engagement_fetched_at
      end
    end

    test "#perform passes the known guild id to the Discord read" do
      parts = [{"index" => 0, "message_id" => "m1", "channel_id" => "c1"}]
      delivery = create(
        :announcement_delivery,
        announcement: @announcement, channel: "discord", status: "succeeded", delivered_at: 1.hour.ago,
        posted_parts: parts, engagement: {"reactions" => [], "guild_id" => "g1"}
      )
      ::Discord::Engagement.stubs(:configured?).returns(true)
      ::Discord::Engagement.any_instance.expects(:fetch).with(parts, guild_id: "g1")
        .returns({"reactions" => [{"emoji" => "🚀", "count" => 2}], "guild_id" => "g1"})

      Announcements::RefreshEngagementJob.new.perform(delivery.id)

      assert_equal 2, delivery.reload.engagement["reactions"].first["count"]
    end

    test "#perform leaves the last counts standing when the platform fails" do
      delivery = create(
        :announcement_delivery,
        announcement: @announcement, channel: "bluesky", status: "succeeded", delivered_at: 1.hour.ago,
        posted_parts: [{"uri" => "at://1"}], engagement: {"likes" => 1}, engagement_fetched_at: 2.hours.ago
      )
      ::Bsky::Engagement.any_instance.stubs(:fetch).raises(::Bsky::Engagement::Error, "502")

      assert_no_changes -> { delivery.reload.engagement_fetched_at } do
        Announcements::RefreshEngagementJob.new.perform(delivery.id)
      end
      assert_equal({"likes" => 1}, delivery.engagement)
    end

    test "#perform reads nothing for X" do
      delivery = create(:announcement_delivery, announcement: @announcement, channel: "x", status: "succeeded", delivered_at: 1.hour.ago)
      ::Bsky::Engagement.any_instance.expects(:fetch).never

      Announcements::RefreshEngagementJob.new.perform(delivery.id)

      assert_nil delivery.reload.engagement_fetched_at
    end
  end
end
