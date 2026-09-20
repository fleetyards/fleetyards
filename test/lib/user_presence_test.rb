# frozen_string_literal: true

require "test_helper"

class UserPresenceTest < ActiveSupport::TestCase
  setup do
    UserPresence.reset!
    @user = SecureRandom.uuid
    @other = SecureRandom.uuid
  end

  teardown do
    UserPresence.reset!
  end

  test "#connect announces the first connection only" do
    assert UserPresence.connect(@user, "tab-1")
    refute UserPresence.connect(@user, "tab-2")
  end

  test "#online? holds while any connection is live" do
    UserPresence.connect(@user, "tab-1")
    UserPresence.connect(@user, "tab-2")

    UserPresence.disconnect(@user, "tab-1")

    assert UserPresence.online?(@user)
  end

  test "a connection stops counting once its grace has run out" do
    UserPresence.connect(@user, "tab-1")
    UserPresence.disconnect(@user, "tab-1")

    travel UserPresence::GRACE + 1.second do
      refute UserPresence.online?(@user)
    end
  end

  test "a connection nothing beats for stops counting after the TTL" do
    UserPresence.connect(@user, "tab-1")

    travel UserPresence::TTL + 1.second do
      refute UserPresence.online?(@user)
    end
  end

  test "a heartbeat keeps a connection counting past the TTL" do
    UserPresence.connect(@user, "tab-1")

    travel UserPresence::HEARTBEAT_INTERVAL do
      UserPresence.heartbeat(@user, "tab-1")
    end

    travel UserPresence::TTL + 1.second do
      assert UserPresence.online?(@user)
    end
  end

  test "#online_user_ids reads every live user in one pass" do
    UserPresence.connect(@user, "tab-1")
    UserPresence.connect(@other, "phone")

    assert_equal [@user, @other].to_set, UserPresence.online_user_ids
  end

  test "#reconcile emits an offline transition once the grace has run out" do
    UserPresence.connect(@user, "tab-1")
    UserPresence.disconnect(@user, "tab-1")

    assert_empty UserPresence.reconcile

    travel UserPresence::GRACE + 1.second do
      assert_equal [[@user, false]], UserPresence.reconcile
      assert_empty UserPresence.reconcile
    end
  end

  test "#reconcile emits an online transition for a connection nothing announced" do
    UserPresence.reset!
    UserPresence.heartbeat(@user, "tab-1")

    assert_equal [[@user, true]], UserPresence.reconcile
  end

  test "a reload emits nothing" do
    UserPresence.connect(@user, "tab-1")
    UserPresence.disconnect(@user, "tab-1")

    travel 2.seconds do
      refute UserPresence.connect(@user, "tab-2")
    end

    travel UserPresence::GRACE + 1.second do
      assert_empty UserPresence.reconcile
      assert UserPresence.online?(@user)
    end
  end

  test "#reconcile settles only the users it was given" do
    UserPresence.connect(@user, "tab-1")
    UserPresence.connect(@other, "phone")
    UserPresence.disconnect(@user, "tab-1")
    UserPresence.disconnect(@other, "phone")

    travel UserPresence::GRACE + 1.second do
      assert_equal [[@user, false]], UserPresence.reconcile(user_ids: [@user])
      assert_equal [[@other, false]], UserPresence.reconcile
    end
  end

  test "#sweep drops members nothing can see any more" do
    UserPresence.connect(@user, "tab-1")

    travel UserPresence::TTL + 1.second do
      UserPresence.sweep

      assert_empty UserPresence.online_user_ids
    end
  end
end
