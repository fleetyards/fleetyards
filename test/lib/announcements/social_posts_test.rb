# frozen_string_literal: true

require "test_helper"

module Announcements
  class SocialPostsTest < ActiveSupport::TestCase
    test "composes one post from the title, the body and the link" do
      announcement = build(:announcement, :with_link, title: "Contracts", body: "Fleets can post jobs now.")

      assert_equal(
        ["Contracts\n\nFleets can post jobs now.\n\nhttps://#{Rails.configuration.app.domain}/fleets/"],
        SocialPosts.call(announcement, platform: Platform::BLUESKY)
      )
    end

    test "takes only the first paragraph of a body" do
      announcement = build(:announcement, title: "T", body: "First.\n\nSecond.")

      assert_equal ["T\n\nFirst."], SocialPosts.call(announcement, platform: Platform::BLUESKY)
    end

    test "keeps the whole link and truncates the text around it" do
      announcement = build(:announcement, :with_link, title: "T", body: "x" * 400)
      link = "https://#{Rails.configuration.app.domain}/fleets/"

      post = SocialPosts.call(announcement, platform: Platform::X).sole

      # Measured the way X measures: the link is billed at 23 whatever its real
      # length, so plain characters would read as over when it is not.
      assert_operator Platform::X.length(post), :<=, Platform::X.limit
      assert post.end_with?(link)
      assert_includes post, "…"
    end

    test "strips markdown rather than shipping the syntax" do
      announcement = build(:announcement, title: "T", body: "## Heading\n\nA **bold** [link](https://example.com) and `code`.")

      assert_equal ["T\n\nHeading"], SocialPosts.call(announcement, platform: Platform::BLUESKY)
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
        SocialPosts.call(announcement, platform: Platform::BLUESKY)
      )
    end

    # Never trimmed on the way out. An over-long part is refused at save, by
    # the platforms the announcement actually selected -- trimming here would
    # silently rewrite copy somebody measured.
    test "hands an authored part back untouched, whatever its length" do
      announcement = build(:announcement, social_parts: ["y" * 300])

      assert_equal 300, SocialPosts.call(announcement, platform: Platform::BLUESKY).sole.length
      assert_equal 300, SocialPosts.call(announcement, platform: Platform::X).sole.length
    end

    test ".plain_text leaves plain prose alone" do
      assert_equal "Just words.", SocialPosts.plain_text("Just words.")
      assert_equal "", SocialPosts.plain_text(nil)
    end
  end
end
