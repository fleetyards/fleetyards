# frozen_string_literal: true

require "test_helper"

module Announcements
  class PlatformTest < ActiveSupport::TestCase
    # Pinned against the same cases as app/frontend/shared/utils/socialCounters.ts.
    # If the two disagree, the editor shows an author a number the dry run and
    # the platform both contradict.
    CASES = [
      ["latin", "abcdefghij", 10],
      ["CJK", "公告测试内容", 6],
      ["rocket emoji", "🚀", 1],
      ["heart with variation selector", "❤️", 1],
      ["ZWJ family", "👨‍👩‍👧", 1],
      ["a URL", "a https://fleetyards.net/a/very/long/path", 2 + 39],
      ["an ellipsis", "…", 1],
      ["empty", "", 0]
    ].freeze

    CASES.each do |name, text, bluesky|
      test "counts #{name}" do
        assert_equal bluesky, Platform::BLUESKY.length(text)
      end
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
      %w[bluesky discord].each do |key|
        platform = Platform.for(key)

        assert_operator platform.length(platform.truncate("a" * 500, to: 100)), :<=, 100
      end
    end

    test "#truncate leaves text that already fits alone" do
      assert_equal "short", Platform::BLUESKY.truncate("short", to: 100)
    end

    test ".for raises on a platform it does not know" do
      assert_raises(ArgumentError) { Platform.for(:mastodon) }
    end
  end
end
