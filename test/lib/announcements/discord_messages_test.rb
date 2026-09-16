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
