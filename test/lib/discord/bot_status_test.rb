# frozen_string_literal: true

require "test_helper"

module Discord
  class BotStatusTest < ActiveSupport::TestCase
    setup do
      BotStatus.stubs(:store).returns(ActiveSupport::Cache::MemoryStore.new)
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

    test "keeps its own store, so a null Rails.cache in development does not lose it" do
      BotStatus.unstub(:store)
      Rails.stubs(:cache).returns(ActiveSupport::Cache::NullStore.new)

      assert_instance_of ActiveSupport::Cache::RedisCacheStore, BotStatus.store
    end
  end
end
