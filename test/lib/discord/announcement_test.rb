# frozen_string_literal: true

require "test_helper"
require "discord/announcement"

module Discord
  class AnnouncementTest < ActiveSupport::TestCase
    test "posts the announcement's own title, body and link" do
      announcement = build(:announcement, :with_link, title: "Contracts", body: "Fleets can post **jobs** now.")
      webhook = Discord::Announcement.new(announcement:)

      assert_equal "Contracts", webhook.title
      assert_equal "Fleets can post **jobs** now.", webhook.message
      assert_equal "https://#{Rails.configuration.app.domain}/fleets/", webhook.url
    end

    test "truncates a body that would blow Discord's message cap" do
      announcement = build(:announcement, body: "x" * 3_000)

      assert_equal Discord::Announcement::MAX_MESSAGE_LENGTH, Discord::Announcement.new(announcement:).message.length
    end

    test "#run is a no-op without an updates endpoint" do
      Rails.application.credentials.stubs(:discord_updates_endpoint).returns(nil)

      refute Discord::Announcement.configured?
      assert_nil Discord::Announcement.new(announcement: build(:announcement)).run
    end
  end
end
