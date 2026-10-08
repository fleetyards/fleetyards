# frozen_string_literal: true

require "test_helper"
require "discord/message_length"

module Discord
  class MessageLengthTest < ActiveSupport::TestCase
    test "an emoji outside the basic plane counts twice" do
      assert_equal 2, MessageLength.of("🚀")
      assert_equal 1, MessageLength.of("é")
    end

    test "truncates to Discord's limit without splitting a character" do
      truncated = MessageLength.truncate("🚀" * 1500)

      assert_equal 2000, MessageLength.of(truncated)
      assert truncated.valid_encoding?
    end

    test "truncates to a smaller limit when given one" do
      assert_equal "abc", MessageLength.truncate("abcdef", 3)
      assert MessageLength.fits?("abc", 3)
      refute MessageLength.fits?("abcd", 3)
    end

    test "marks a cut with the omission, counted within the limit" do
      assert_equal "ab…", MessageLength.truncate("abcdef", 3, omission: "…")
      assert_equal "abc", MessageLength.truncate("abc", 3, omission: "…")
    end

    test "leaves a message that fits alone" do
      assert_equal "hello", MessageLength.truncate("hello")
    end
  end
end
