# frozen_string_literal: true

require "test_helper"

module Announcements
  class DiscordMessagesTest < ActiveSupport::TestCase
    test "composes one message from the title, the body and the link" do
      announcement = build(:announcement, :with_link, title: "Contracts", body: "Jobs now.")

      assert_equal(
        ["**Contracts**\nJobs now.\nhttps://#{Rails.configuration.app.domain}/fleets/"],
        DiscordMessages.call(announcement)
      )
    end

    # The bug this replaces: a `truncate(1_800)` over a launch announcement
    # dropped everything after the cut, and what came after was the part about
    # what stays free.
    test "packs a body past the cap into further messages rather than cutting it" do
      body = (["x" * 900] * 4).join("\n\n")
      messages = DiscordMessages.call(build(:announcement, body:))

      assert_operator messages.size, :>, 1
      messages.each { |message| assert_operator message.length, :<=, Announcement::DISCORD_PART_LIMIT }
      assert_equal 4 * 900, messages.join.scan("x").length
    end

    test "hard-splits a single paragraph longer than one message" do
      messages = DiscordMessages.call(build(:announcement, body: "y" * 5_000))

      assert_operator messages.size, :>, 2
      assert_equal 5_000, messages.join.scan("y").length
    end

    # 2,000 emoji are 2,000 clusters and 4,000 UTF-16 code units, and Discord
    # counts the latter -- a chunk sliced by cluster count is rejected.
    test "hard-splits by what Discord charges, not by cluster count" do
      messages = DiscordMessages.call(build(:announcement, body: "🚀" * 3_000))

      messages.each do |message|
        assert_operator Announcements::Platform::DISCORD.length(message), :<=, Announcement::DISCORD_PART_LIMIT
      end

      assert_equal 3_000, messages.join.scan("🚀").length
    end

    # A 255-character title is longer than any fixed reserve worth setting.
    test "packs the first message against the real length of its heading" do
      announcement = build(:announcement, title: "T" * 255, body: "x" * 5_000)

      DiscordMessages.call(announcement).each do |message|
        assert_operator Announcements::Platform::DISCORD.length(message), :<=, Announcement::DISCORD_PART_LIMIT
      end
    end

    test "posts the author's own messages verbatim and in order" do
      announcement = build(
        :announcement, :with_link, title: "Ignored",
        discord_parts: ["## Fleet Ops is in public beta", "**How to switch them on**"]
      )

      assert_equal(
        ["## Fleet Ops is in public beta", "**How to switch them on**"],
        DiscordMessages.call(announcement)
      )
    end

    test "puts the link on the last message, not the first" do
      body = (["z" * 900] * 3).join("\n\n")
      messages = DiscordMessages.call(build(:announcement, :with_link, body:))
      link = "https://#{Rails.configuration.app.domain}/fleets/"

      refute_includes messages.first, link
      assert messages.last.end_with?(link)
    end
  end
end
