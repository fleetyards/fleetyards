# frozen_string_literal: true

require "test_helper"

module Announcements
  class SocialPostsTest < ActiveSupport::TestCase
    test "composes one post from the title, the body and the link" do
      announcement = build(:announcement, :with_link, title: "Contracts", body: "Fleets can post jobs now.")

      assert_equal(
        ["Contracts\n\nFleets can post jobs now.\n\nhttps://#{Rails.configuration.app.domain}/fleets/"],
        SocialPosts.call(announcement, limit: 300)
      )
    end

    test "takes only the first paragraph of a body" do
      announcement = build(:announcement, title: "T", body: "First.\n\nSecond.")

      assert_equal ["T\n\nFirst."], SocialPosts.call(announcement, limit: 300)
    end

    test "keeps the whole link and truncates the text around it" do
      announcement = build(:announcement, :with_link, title: "T", body: "x" * 400)
      link = "https://#{Rails.configuration.app.domain}/fleets/"

      post = SocialPosts.call(announcement, limit: 280).sole

      assert_operator post.length, :<=, 280
      assert post.end_with?(link)
      assert_includes post, "…"
    end

    test "strips markdown rather than shipping the syntax" do
      announcement = build(:announcement, title: "T", body: "## Heading\n\nA **bold** [link](https://example.com) and `code`.")

      assert_equal ["T\n\nHeading"], SocialPosts.call(announcement, limit: 300)
    end

    # The authored case. Where a thread breaks, and which post carries the
    # link, are editorial decisions -- a composer that re-wrapped them would
    # move a boundary somebody chose.
    test "posts the author's own parts verbatim and in order" do
      announcement = build(
        :announcement,
        title: "Ignored",
        social_parts: ["Fleet Ops is in public beta 🚀", "Free in beta, then supporter features."]
      )

      assert_equal(
        ["Fleet Ops is in public beta 🚀", "Free in beta, then supporter features."],
        SocialPosts.call(announcement, limit: 300)
      )
    end

    # The model's bound is Bluesky's 300 and X stops at 280, so a legal part
    # can still be too long for one of the two platforms.
    test "trims an authored part to the platform it is going to" do
      announcement = build(:announcement, social_parts: ["y" * 300])

      assert_equal 300, SocialPosts.call(announcement, limit: 300).sole.length
      assert_equal 280, SocialPosts.call(announcement, limit: 280).sole.length
    end

    test ".plain_text leaves plain prose alone" do
      assert_equal "Just words.", SocialPosts.plain_text("Just words.")
      assert_equal "", SocialPosts.plain_text(nil)
    end
  end
end
