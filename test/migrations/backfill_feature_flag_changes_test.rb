# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20260916170000_backfill_feature_flag_changes.rb")

# Run against real flipper_features / flipper_gates rows rather than through
# Flipper, because the test environment's Flipper is a memory adapter -- nothing
# it does reaches the tables this migration reads.
class BackfillFeatureFlagChangesTest < ActiveSupport::TestCase
  FEATURES = Flipper::Adapters::ActiveRecord::Feature
  GATES = Flipper::Adapters::ActiveRecord::Gate

  setup do
    FeatureFlagChange.delete_all
    GATES.delete_all
    FEATURES.delete_all
  end

  def feature(key, created_at:)
    FEATURES.create!(key: key, created_at: created_at, updated_at: created_at)
  end

  def gate(key, name, value, at:)
    GATES.create!(feature_key: key, key: name, value: value, created_at: at, updated_at: at)
  end

  def backfill
    BackfillFeatureFlagChanges.new.up
  end

  test "a fully open flag lands as an add and the boolean gate that opened it" do
    added = 30.days.ago
    opened = 5.days.ago
    feature("wide_open", created_at: added)
    gate("wide_open", "boolean", "true", at: opened)

    backfill

    rows = FeatureFlagChange.for_feature("wide_open").order(:created_at)

    assert_equal %w[add enable], rows.map(&:operation)
    assert_equal [FeatureFlagChange::STATE_OFF, FeatureFlagChange::STATE_ON], rows.map(&:state_after)
    assert_in_delta opened, FeatureFlagChange.fully_on_since("wide_open"), 1.second
  end

  # The gate is stored under `actors` and named `actor`. A backfilled row has to
  # agree with the live ones the subscriber writes.
  test "actor gates are recorded under the name the subscriber uses" do
    feature("rolling_out", created_at: 10.days.ago)
    gate("rolling_out", "actors", "User;abc", at: 2.days.ago)

    backfill

    change = FeatureFlagChange.for_feature("rolling_out").find_by(operation: "enable")

    assert_equal "actor", change.gate_name
    assert_equal "User;abc", change.thing
    assert_equal FeatureFlagChange::STATE_CONDITIONAL, change.state_after
    assert_nil FeatureFlagChange.fully_on_since("rolling_out")
  end

  test "each actor is its own row, and the flag stays conditional throughout" do
    feature("rolling_out", created_at: 10.days.ago)
    gate("rolling_out", "actors", "User;one", at: 3.days.ago)
    gate("rolling_out", "actors", "User;two", at: 1.day.ago)

    backfill

    states = FeatureFlagChange.for_feature("rolling_out").order(:created_at).pluck(:state_after)

    assert_equal %w[off conditional conditional], states
  end

  # 0 is the gate's default, so the row's presence is not enough to call the flag
  # conditional.
  test "a percentage of zero leaves the flag off" do
    feature("dormant", created_at: 10.days.ago)
    gate("dormant", "percentage_of_actors", "0", at: 1.day.ago)

    backfill

    assert_equal %w[off off], FeatureFlagChange.for_feature("dormant").order(:created_at).pluck(:state_after)
  end

  test "a percentage above zero makes it conditional" do
    feature("partial", created_at: 10.days.ago)
    gate("partial", "percentage_of_actors", "25", at: 1.day.ago)

    backfill

    change = FeatureFlagChange.for_feature("partial").find_by(operation: "enable")

    assert_equal FeatureFlagChange::STATE_CONDITIONAL, change.state_after
    assert_equal "25", change.thing
  end

  test "running twice does not double the history" do
    feature("wide_open", created_at: 30.days.ago)
    gate("wide_open", "boolean", "true", at: 5.days.ago)

    backfill
    backfill

    assert_equal 2, FeatureFlagChange.for_feature("wide_open").count
  end

  test "down clears the seeded rows and leaves recorded ones alone" do
    feature("wide_open", created_at: 30.days.ago)
    gate("wide_open", "boolean", "true", at: 5.days.ago)
    backfill

    live = FeatureFlagChange.create!(
      feature_name: "wide_open",
      operation: "disable",
      state_after: FeatureFlagChange::STATE_OFF,
      source: FeatureFlagChange::SOURCE_ADMIN
    )

    BackfillFeatureFlagChanges.new.down

    assert_equal [live], FeatureFlagChange.all.to_a
  end
end
