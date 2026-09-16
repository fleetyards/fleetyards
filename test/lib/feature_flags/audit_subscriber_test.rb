# frozen_string_literal: true

require "test_helper"
require "support/flipper_audit_test_helpers"

module FeatureFlags
  class AuditSubscriberTest < ActiveSupport::TestCase
    setup do
      FeatureFlagChange.delete_all
    end

    test "an enable writes one row describing the boolean gate" do
      with_flag_auditing { Flipper.enable(:audited) }

      change = FeatureFlagChange.sole

      assert_equal "audited", change.feature_name
      assert_equal "enable", change.operation
      assert_equal "boolean", change.gate_name
      assert_equal "true", change.thing
      assert_equal FeatureFlagChange::STATE_ON, change.state_after
    end

    # The same event name carries every read, and reads outnumber writes by
    # several orders of magnitude.
    test "a flag check writes nothing" do
      with_flag_auditing do
        Flipper.enable(:audited)
        FeatureFlagChange.delete_all

        Flipper.enabled?(:audited)
        Flipper.exist?(:audited)
      end

      assert_empty FeatureFlagChange.all
    end

    test "an actor gate records the actor and leaves the flag conditional" do
      user = FactoryBot.create(:user)

      with_flag_auditing { Flipper.enable_actor(:audited, user) }

      change = FeatureFlagChange.sole

      assert_equal "actor", change.gate_name
      assert_equal user.flipper_id, change.thing
      assert_equal FeatureFlagChange::STATE_CONDITIONAL, change.state_after
    end

    # The state is read back rather than derived from the operation: disabling
    # one actor of two leaves the flag conditional, and only the second turns it
    # off.
    test "disabling the last actor records off, not the operation's name" do
      first = FactoryBot.create(:user)
      second = FactoryBot.create(:user)

      with_flag_auditing do
        Flipper.enable_actor(:audited, first)
        Flipper.enable_actor(:audited, second)
        Flipper.disable_actor(:audited, first)
        Flipper.disable_actor(:audited, second)
      end

      states = FeatureFlagChange.for_feature(:audited).order(:created_at).pluck(:state_after)

      assert_equal %w[conditional conditional conditional off], states
    end

    test "attribution comes from FeatureFlags::Current" do
      admin = FactoryBot.create(:admin_user)

      with_flag_auditing do
        Current.with(source: FeatureFlagChange::SOURCE_ADMIN, admin_user: admin) do
          Flipper.enable(:audited)
        end
      end

      change = FeatureFlagChange.sole

      assert_equal FeatureFlagChange::SOURCE_ADMIN, change.source
      assert_equal admin, change.admin_user
      assert_nil change.user
    end

    test "an unattributed change is recorded as console" do
      with_flag_auditing { Flipper.enable(:audited) }

      assert_equal FeatureFlagChange::SOURCE_CONSOLE, FeatureFlagChange.sole.source
    end

    test "Current is restored after the block, so a nested source cannot strand the outer one" do
      Current.with(source: FeatureFlagChange::SOURCE_ADMIN) do
        Current.with(source: FeatureFlagChange::SOURCE_SYNC) { nil }

        assert_equal FeatureFlagChange::SOURCE_ADMIN, Current.source
      end

      assert_nil Current.source
    end

    # Reporting the failure must not become the failure: this subscriber runs
    # after Flipper has written the gate, so anything escaping here would report
    # a mutation that succeeded as failed.
    test "a failing write survives a failing error report" do
      FeatureFlagChange.stubs(:record!).raises(ActiveRecord::StatementInvalid, "nope")
      Appsignal.stubs(:report_error).raises(RuntimeError, "appsignal is down too")

      with_flag_auditing do
        Flipper.enable(:audited)

        assert Flipper.enabled?(:audited)
      end
    end

    # An audit log able to break the toggle it is auditing would be worse than
    # no audit log.
    test "a failing write leaves the flag change itself successful" do
      FeatureFlagChange.stubs(:record!).raises(ActiveRecord::StatementInvalid, "nope")
      Appsignal.expects(:report_error).once

      with_flag_auditing do
        Flipper.enable(:audited)

        assert Flipper.enabled?(:audited)
      end

      assert_empty FeatureFlagChange.all
    end
  end
end
