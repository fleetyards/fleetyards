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
      client.define_singleton_method(:execute) do |_builder = nil, _wait = false, &block|
        builder = OpenStruct.new
        block.call(builder)
        posted << builder.content
        OpenStruct.new(body: {id: "m#{posted.size}", channel_id: "c1"}.to_json)
      end
      Discordrb::Webhooks::Client.stubs(:new).returns(client)

      Discord::Announcement.new(announcement:).run

      # Each carries its position marker; the copy under it is untouched.
      assert_equal ["-# 1/2", "-# ↳ 2/2"], posted.map { |body| body.lines.first.strip }
      assert_equal(
        ["## Fleet Ops is in public beta", "**How to switch them on**"],
        posted.map { |body| body.lines.drop(1).join.strip }
      )
    end

    # The ids are what the reactions are read back from later; without `wait`
    # Discord answers 204 and they are never known.
    test "#run waits for each message and yields what Discord created" do
      announcement = build(:announcement, discord_parts: ["One", "Two"])
      Rails.application.credentials.stubs(:discord_updates_endpoint).returns("https://discord.test/updates")

      waits = []
      client = Object.new
      client.define_singleton_method(:execute) do |_builder = nil, wait = false, &block|
        waits << wait
        block.call(OpenStruct.new)
        OpenStruct.new(body: {id: "m#{waits.size}", channel_id: "c1"}.to_json)
      end
      Discordrb::Webhooks::Client.stubs(:new).returns(client)

      yielded = []
      Discord::Announcement.new(announcement:).run { |index, message| yielded << [index, message["id"]] }

      assert_equal [true, true], waits
      assert_equal [[0, "m1"], [1, "m2"]], yielded
    end

    test "#run is a no-op without an updates endpoint" do
      Rails.application.credentials.stubs(:discord_updates_endpoint).returns(nil)

      refute Discord::Announcement.configured?
      assert_nil Discord::Announcement.new(announcement: build(:announcement)).run
    end
  end
end
