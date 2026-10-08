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

    # Through Redis itself, read back by a store of its own the way the web
    # process would, and with a null Rails.cache as development has by default.
    test "a report the bot writes can be read by another process" do
      BotStatus.unstub(:store)
      BotStatus.instance_variable_set(:@store, nil)
      Rails.stubs(:cache).returns(ActiveSupport::Cache::NullStore.new)

      BotStatus.record!(members_intent: true)
      other_process = ActiveSupport::Cache::RedisCacheStore.new(
        url: Rails.configuration.redis.url,
        db: Rails.configuration.redis.cache_db,
        namespace: "fleetyards-#{Rails.env}"
      )

      assert_equal true, other_process.read(BotStatus::KEY)["members_intent"]
    ensure
      BotStatus.store.delete(BotStatus::KEY)
      BotStatus.instance_variable_set(:@store, nil)
    end
  end
end
