# frozen_string_literal: true

require "test_helper"

module Announcements
  class PlatformTest < ActiveSupport::TestCase
    # Pinned against the same cases as app/frontend/shared/utils/socialCounters.ts.
    # If the two disagree, the editor shows an author a number the dry run and
    # the platform both contradict.
    CASES = [
      ["latin", "abcdefghij", 10, 10],
      # X weights CJK at two; Bluesky counts one grapheme each.
      ["CJK", "公告测试内容", 12, 6],
      ["rocket emoji", "🚀", 2, 1],
      ["heart with variation selector", "❤️", 2, 1],
      ["ZWJ family", "👨‍👩‍👧", 2, 1],
      # X bills any URL at 23 regardless of length; Bluesky counts it in full.
      ["a URL", "a https://fleetyards.net/a/very/long/path", 2 + 23, 2 + 39],
      # X's extractor stops before trailing punctuation, so the full stop is
      # text rather than free inside the 23.
      ["a URL with a trailing full stop", "Read https://fleetyards.net.", 5 + 23 + 1, 28],
      # A URL ends at the first character RFC 3986 does not allow. CJK needs no
      # space before it, so `\S+` swallowed it into the flat 23.
      ["CJK straight after a URL", "https://fleetyards.net公告公告", 23 + 8, 22 + 4],
      ["empty", "", 0, 0]
    ].freeze

    CASES.each do |name, text, x, bluesky|
      test "counts #{name}" do
        assert_equal x, Platform::X.length(text)
        assert_equal bluesky, Platform::BLUESKY.length(text)
      end
    end

    # The ellipsis sits outside X's light ranges, so it weighs two there.
    test "weighs the ellipsis the way X does" do
      assert_equal 2, Platform::X.length("…")
      assert_equal 1, Platform::BLUESKY.length("…")
    end

    # Discord counts UTF-16 code units, so anything above the BMP costs two.
    test "counts Discord in UTF-16 code units" do
      assert_equal 20, Platform::DISCORD.length("🚀" * 10)
      assert_equal 10, Platform::DISCORD.length("a" * 10)
      assert_equal 2, Platform::DISCORD.length("公告")
    end

    test "#truncate never splits a grapheme cluster" do
      assert_equal "🚀🚀🚀🚀…", Platform::BLUESKY.truncate("🚀" * 10, to: 5)
    end

    # The ellipsis has to be paid for out of the budget, or a post trimmed to
    # the cap lands one over it.
    test "#truncate budgets the ellipsis at what the platform charges" do
      %w[x bluesky].each do |key|
        platform = Platform.for(key)

        assert_operator platform.length(platform.truncate("a" * 500, to: 100)), :<=, 100
      end
    end

    test "#truncate leaves text that already fits alone" do
      assert_equal "short", Platform::X.truncate("short", to: 100)
    end

    test ".for raises on a platform it does not know" do
      assert_raises(ArgumentError) { Platform.for(:mastodon) }
    end
  end
end
