# frozen_string_literal: true

require "test_helper"
require "discord/announcement_preview"

module Discord
  class AnnouncementPreviewTest < ActiveSupport::TestCase
    setup do
      Rails.application.credentials.stubs(:discord_admin_endpoint).returns("https://discord.test/admin")
    end

    test "goes to the admin channel, not the updates channel" do
      preview = Discord::AnnouncementPreview.new(announcement: build(:announcement))

      assert_equal "https://discord.test/admin", preview.webhook_endpoint
    end

    test "marks itself as a test and names the channels it would reach" do
      announcement = build(:announcement, :social, title: "Contracts")
      preview = Discord::AnnouncementPreview.new(announcement:)

      assert_equal I18n.t("announcements.preview.title", title: "Contracts"), preview.title
      assert_includes preview.message, I18n.t("announcements.channels.in_app")
      assert_includes preview.message, I18n.t("announcements.channels.bluesky")
    end

    # The composed string, not the body it was built from: a truncated post is
    # the one thing the form cannot show.
    test "carries each social post with its character count" do
      announcement = build(:announcement, :social, :with_link, title: "T", body: "The whole story.")
      preview = Discord::AnnouncementPreview.new(announcement:)

      bluesky = Announcements::SocialMessage.call(announcement, limit: ::Bsky::Post::MAX_LENGTH)

      assert_includes preview.message, bluesky.lines.first.strip
      assert_includes preview.message, "#{bluesky.length}/#{::Bsky::Post::MAX_LENGTH}"
    end

    test "leaves out a channel the announcement did not ask for" do
      announcement = build(:announcement, post_bluesky: true)
      message = Discord::AnnouncementPreview.new(announcement:).message

      assert_includes message, "/#{::Bsky::Post::MAX_LENGTH}"
      refute_includes message, "/#{::XCom::Post::MAX_LENGTH}"
    end

    test "is not configured without an admin webhook" do
      Rails.application.credentials.stubs(:discord_admin_endpoint).returns(nil)

      refute Discord::AnnouncementPreview.configured?
    end
  end
end
