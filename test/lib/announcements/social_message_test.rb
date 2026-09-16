# frozen_string_literal: true

require "test_helper"

module Announcements
  class SocialMessageTest < ActiveSupport::TestCase
    test "joins the title, the body and the link" do
      announcement = build(:announcement, :with_link, title: "Contracts", body: "Fleets can post jobs now.")

      assert_equal(
        "Contracts\n\nFleets can post jobs now.\n\nhttps://#{Rails.configuration.app.domain}/fleets/",
        SocialMessage.call(announcement, limit: 300)
      )
    end

    test "prefers social_body over the markdown body" do
      announcement = build(:announcement, title: "Contracts", body: "The long version.", social_body: "The short one.")

      assert_equal "Contracts\n\nThe short one.", SocialMessage.call(announcement, limit: 300)
    end

    test "takes only the first paragraph of a body" do
      announcement = build(:announcement, title: "T", body: "First.\n\nSecond.")

      assert_equal "T\n\nFirst.", SocialMessage.call(announcement, limit: 300)
    end

    test "keeps the whole link and truncates the text around it" do
      announcement = build(:announcement, :with_link, title: "T", body: "x" * 400)
      link = "https://#{Rails.configuration.app.domain}/fleets/"

      message = SocialMessage.call(announcement, limit: 280)

      assert_operator message.length, :<=, 280
      assert message.end_with?(link)
      assert_includes message, "…"
    end

    test "strips markdown rather than shipping the syntax" do
      announcement = build(:announcement, title: "T", body: "## Heading\n\nA **bold** [link](https://example.com) and `code`.")

      assert_equal "T\n\nHeading", SocialMessage.call(announcement, limit: 300)
    end

    test ".plain_text leaves plain prose alone" do
      assert_equal "Just words.", SocialMessage.plain_text("Just words.")
      assert_equal "", SocialMessage.plain_text(nil)
    end
  end
end
