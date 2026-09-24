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

    test "leaves a message that fits alone" do
      assert_equal "hello", MessageLength.truncate("hello")
    end
  end
end
