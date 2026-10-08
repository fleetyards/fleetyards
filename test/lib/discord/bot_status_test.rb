# frozen_string_literal: true

require "test_helper"

module Discord
  class BotStatusTest < ActiveSupport::TestCase
    setup do
      Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)
    end

    test "reports what the bot connected with" do
      BotStatus.record!(members_intent: true)

      assert_equal true, BotStatus.current["members_intent"]
    end

    test "reports nothing once the bot has gone quiet" do
      BotStatus.record!(members_intent: true)

      travel BotStatus::STALE_AFTER + 1.second do
        assert_nil BotStatus.current
      end
    end

    test "reports nothing once the bot disconnected" do
      BotStatus.record!(members_intent: true)

      BotStatus.clear!

      assert_nil BotStatus.current
    end
  end
end
