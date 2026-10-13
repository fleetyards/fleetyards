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
      assert_includes preview.send(:contents).join("\n"), I18n.t("announcements.channels.in_app")
      assert_includes preview.send(:contents).join("\n"), I18n.t("announcements.channels.bluesky")
    end

    # The composed string, not the body it was built from: a truncated post is
    # the one thing the form cannot show.
    test "carries each social post with its character count" do
      announcement = build(:announcement, :social, :with_link, title: "T", body: "The whole story.")
      preview = Discord::AnnouncementPreview.new(announcement:)

      bluesky = Announcements::SocialPosts.call(announcement, platform: Announcements::Platform::BLUESKY).sole

      assert_includes preview.send(:contents).join("\n"), bluesky.lines.first.strip
      assert_includes preview.send(:contents).join("\n"), "#{bluesky.length}/#{Announcements::Platform::BLUESKY.limit}"
    end

    # Where a thread breaks and what each post costs is the whole question a
    # dry run answers.
    test "quotes every post of a thread with its own position and count" do
      announcement = build(:announcement, :social, social_parts: ["First post", "Second post"])
      message = Discord::AnnouncementPreview.new(announcement:).send(:contents).join("\n")

      assert_includes message, "> First post"
      assert_includes message, "> Second post"
      assert_includes message, "1/2"
      assert_includes message, "2/2"
    end

    test "quotes every Discord message an announcement would post" do
      announcement = build(:announcement, :social, discord_parts: ["Message one", "Message two"])
      message = Discord::AnnouncementPreview.new(announcement:).send(:contents).join("\n")

      assert_includes message, "> Message one"
      assert_includes message, "> Message two"
    end

    # Bluesky counts graphemes, so an emoji is one however many codepoints
    # spell it -- which is exactly what an author needs to see.
    test "counts a Bluesky post the way Bluesky does" do
      announcement = build(:announcement, post_bluesky: true, social_parts: ["Launch 👨‍👩‍👧"])

      message = Discord::AnnouncementPreview.new(announcement:).send(:contents).join("\n")

      assert_includes message, "8/#{Announcements::Platform::BLUESKY.limit}"
    end

    test "leaves out a channel the announcement did not ask for" do
      announcement = build(:announcement, post_discord: true, discord_parts: ["Hello"])
      message = Discord::AnnouncementPreview.new(announcement:).send(:contents).join("\n")

      refute_includes message, "/#{Announcements::Platform::BLUESKY.limit}"
    end

    test "is not configured without an admin webhook" do
      Rails.application.credentials.stubs(:discord_admin_endpoint).returns(nil)

      refute Discord::AnnouncementPreview.configured?
    end
  end
end
