# frozen_string_literal: true

require "test_helper"
require "discord/announcement"
require "ostruct"

module Discord
  class AnnouncementTest < ActiveSupport::TestCase
    test "posts the announcement's own title, body and link" do
      announcement = build(:announcement, :with_link, title: "Contracts", body: "Fleets can post **jobs** now.")
      webhook = Discord::Announcement.new(announcement:)

      assert_equal "Contracts", webhook.title
      assert_includes webhook.message, "Fleets can post **jobs** now."
      assert_includes webhook.message, "https://#{Rails.configuration.app.domain}/fleets/"
    end

    test "posts every message of a two-message announcement, in order" do
      announcement = build(
        :announcement,
        discord_parts: ["## Fleet Ops is in public beta", "**How to switch them on**"]
      )
      Rails.application.credentials.stubs(:discord_updates_endpoint).returns("https://discord.test/updates")

      posted = []
      client = Object.new
      client.define_singleton_method(:execute) do |&block|
        builder = OpenStruct.new
        block.call(builder)
        posted << builder.content
      end
      Discordrb::Webhooks::Client.stubs(:new).returns(client)

      Discord::Announcement.new(announcement:).run

      assert_equal ["## Fleet Ops is in public beta", "**How to switch them on**"], posted
    end

    test "#run is a no-op without an updates endpoint" do
      Rails.application.credentials.stubs(:discord_updates_endpoint).returns(nil)

      refute Discord::Announcement.configured?
      assert_nil Discord::Announcement.new(announcement: build(:announcement)).run
    end
  end
end
