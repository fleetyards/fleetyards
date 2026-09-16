# frozen_string_literal: true

require "test_helper"

module FeatureFlags
  class StaleReportTest < ActiveSupport::TestCase
    FakeFeature = Struct.new(:name, :state)

    # Stands in for Flipper so the report never depends on the real feature set.
    class FakeFlipper
      def initialize(features)
        @features = features
      end

      def features
        @features.map { |name, state| FakeFeature.new(name, state) }
      end
    end

    setup do
      FeatureFlagChange.delete_all
      @now = Time.zone.parse("2026-09-16 12:00:00")
    end

    def opened(name, days_ago)
      FeatureFlagChange.create!(
        feature_name: name,
        operation: "enable",
        state_after: FeatureFlagChange::STATE_ON,
        source: FeatureFlagChange::SOURCE_BACKFILL,
        created_at: @now - days_ago.days
      )
    end

    def registry(flags)
      Registry.new(raw: flags.to_h { |name, permanent| [name, {"description" => name, "permanent" => permanent}.compact] })
    end

    def report(flipper_states, registry_flags, threshold_days: 30)
      StaleReport.new(
        threshold_days: threshold_days,
        registry: registry(registry_flags),
        flipper: FakeFlipper.new(flipper_states),
        now: @now
      )
    end

    test "a flag open longer than the threshold is listed with its age" do
      opened("old_news", 90)

      entries = report({"old_news" => :on}, {"old_news" => nil}).entries

      assert_equal ["old_news"], entries.map(&:name)
      assert_equal 90, entries.first.days_open
    end

    test "a flag open for less than the threshold is not listed" do
      opened("fresh", 5)

      assert_empty report({"fresh" => :on}, {"fresh" => nil}).entries
    end

    # Being open for a year is the point of a permanent flag, not a symptom.
    test "permanent flags are skipped however old" do
      opened("oauth-github", 400)

      assert_empty report({"oauth-github" => :on}, {"oauth-github" => true}).entries
    end

    # Asked of Flipper rather than of the log: the log could be missing a
    # disable, and a flag that is not open is not a removal candidate.
    test "a flag that is not on for everyone is skipped" do
      opened("rolling_out", 200)

      assert_empty report({"rolling_out" => :conditional}, {"rolling_out" => nil}).entries
    end

    # The report's job is to notice open flags, so one with no recorded history
    # is named rather than dropped.
    test "an open flag with no history is listed as unknown" do
      entries = report({"undocumented" => :on}, {"undocumented" => nil}).entries

      assert_equal ["undocumented"], entries.map(&:name)
      assert_predicate entries.first, :unknown?
    end

    test "the longest-open flag comes first, and an unknown age sorts last" do
      opened("older", 120)
      opened("newer", 60)

      entries = report(
        {"older" => :on, "newer" => :on, "undocumented" => :on},
        {"older" => nil, "newer" => nil, "undocumented" => nil}
      ).entries

      assert_equal %w[older newer undocumented], entries.map(&:name)
    end

    test "to_console counts what it skipped" do
      opened("old_news", 90)
      opened("fresh", 3)

      output = report(
        {"old_news" => :on, "fresh" => :on, "oauth-github" => :on},
        {"old_news" => nil, "fresh" => nil, "oauth-github" => true}
      ).to_console

      assert_includes output, "old_news"
      assert_includes output, "1 of 2 fully open flags, 1 permanent flags skipped."
    end

    test "to_console says so when nothing is stale" do
      assert_includes report({}, {}).to_console, "(none)"
    end
  end
end
