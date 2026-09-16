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
