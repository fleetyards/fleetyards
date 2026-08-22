# frozen_string_literal: true

require "test_helper"

module FeatureFlags
  class SynchronizerTest < ActiveSupport::TestCase
    # Stands in for Flipper so the tests never touch the real feature set.
    class FakeFlipper
      Feature = Struct.new(:key)

      attr_reader :added, :removed

      def initialize(existing = [])
        @existing = existing.dup
        @added = []
        @removed = []
      end

      def features
        @existing.map { |key| Feature.new(key) }
      end

      def add(name)
        @added << name
        @existing << name
      end

      def remove(name)
        @removed << name
        @existing.delete(name)
      end
    end

    def registry(*names)
      Registry.new(raw: names.to_h { |name| [name, {"description" => name}] })
    end

    def sync(registry:, flipper:, **options)
      Synchronizer.new(registry: registry, flipper: flipper, **options).call
    end

    test "adds flags missing from flipper" do
      flipper = FakeFlipper.new(["existing"])

      result = sync(registry: registry("existing", "brand_new"), flipper: flipper)

      assert_equal ["brand_new"], result.added
      assert_equal ["brand_new"], flipper.added
      assert_equal ["existing"], result.unchanged
      assert_predicate result, :changed?
    end

    test "prunes flags absent from the registry" do
      flipper = FakeFlipper.new(%w[keeper orphan])

      result = sync(registry: registry("keeper"), flipper: flipper)

      assert_equal ["orphan"], result.removed
      assert_equal ["orphan"], flipper.removed
    end

    test "pruning a flag also removes its self-service setting" do
      FeatureSetting.create!(feature_name: "orphan", self_service_user: true)
      FeatureSetting.create!(feature_name: "keeper", self_service_user: true)

      sync(registry: registry("keeper"), flipper: FakeFlipper.new(%w[keeper orphan]))

      assert_not FeatureSetting.user_toggleable?("orphan"),
        "a re-declared flag would otherwise come back user-toggleable"
      assert FeatureSetting.user_toggleable?("keeper")
    end

    test "cleans up settings for flags flipper no longer knows about" do
      FeatureSetting.create!(feature_name: "ghost", self_service_user: true)
      flipper = FakeFlipper.new(["keeper"])

      result = sync(registry: registry("keeper"), flipper: flipper)

      assert_empty result.removed, "nothing left in flipper to prune"
      assert_empty flipper.removed
      assert_not FeatureSetting.exists?(feature_name: "ghost"),
        "an interrupted prune must be repaired by the next run"
    end

    test "creates no setting for a flag it adds" do
      sync(registry: registry("fleet_logistics"), flipper: FakeFlipper.new)

      assert_not FeatureSetting.exists?(feature_name: "fleet_logistics"),
        "self-service is the admin UI's call, and a row is what records that call"
    end

    test "never switches self-service on" do
      FeatureSetting.create!(feature_name: "fleet_logistics", self_service_user: false)

      sync(registry: registry("fleet_logistics"), flipper: FakeFlipper.new(["fleet_logistics"]))

      assert_not FeatureSetting.user_toggleable?("fleet_logistics"),
        "a deploy must not overrule an admin who left the toggle off"
    end

    test "never switches self-service off" do
      FeatureSetting.create!(feature_name: "plain", self_service_user: true)

      sync(registry: registry("plain"), flipper: FakeFlipper.new(["plain"]))

      assert FeatureSetting.user_toggleable?("plain"),
        "and must not overrule an admin who switched it on"
    end

    test "leaves the fleet toggle alone" do
      FeatureSetting.create!(feature_name: "plain", self_service_user: true, self_service_fleet: true)

      sync(registry: registry("plain"), flipper: FakeFlipper.new(["plain"]))

      assert FeatureSetting.fleet_toggleable?("plain"),
        "which surfaces a flag is toggleable on is the admin's call too, and the " \
        "registry cannot express it to disagree"
    end

    test "dry_run leaves self-service settings alone" do
      FeatureSetting.create!(feature_name: "orphan", self_service_user: true)

      sync(registry: registry("keeper"), flipper: FakeFlipper.new(%w[keeper orphan]), dry_run: true)

      assert FeatureSetting.user_toggleable?("orphan")
    end

    test "prune: false leaves self-service settings alone" do
      FeatureSetting.create!(feature_name: "orphan", self_service_user: true)

      sync(registry: registry("keeper"), flipper: FakeFlipper.new(%w[keeper orphan]), prune: false)

      assert FeatureSetting.user_toggleable?("orphan")
    end

    test "reports no changes when flipper already matches" do
      flipper = FakeFlipper.new(%w[a b])

      result = sync(registry: registry("a", "b"), flipper: flipper)

      assert_not_predicate result, :changed?
      assert_empty flipper.added
      assert_empty flipper.removed
      assert_equal %w[a b], result.unchanged
    end

    test "prune: false leaves orphans alone but still adds" do
      flipper = FakeFlipper.new(%w[keeper orphan])

      result = sync(registry: registry("keeper", "newcomer"), flipper: flipper, prune: false)

      assert_equal ["newcomer"], result.added
      assert_empty result.removed
      assert_empty flipper.removed
      assert_not result.pruned
    end

    test "dry_run touches nothing but reports the plan" do
      flipper = FakeFlipper.new(%w[keeper orphan])

      result = sync(registry: registry("keeper", "newcomer"), flipper: flipper, dry_run: true)

      assert_equal ["newcomer"], result.added
      assert_equal ["orphan"], result.removed
      assert_empty flipper.added
      assert_empty flipper.removed
      assert result.dry_run
    end

    test "sorts added and removed names" do
      flipper = FakeFlipper.new(%w[zz_orphan aa_orphan])

      result = sync(registry: registry("zz_new", "aa_new"), flipper: flipper)

      assert_equal %w[aa_new zz_new], result.added
      assert_equal %w[aa_orphan zz_orphan], result.removed
    end

    test "to_console summarises a dry run" do
      output = sync(
        registry: registry("newcomer"),
        flipper: FakeFlipper.new(["orphan"]),
        dry_run: true
      ).to_console

      assert_includes output, "DRY RUN"
      assert_includes output, "+ newcomer"
      assert_includes output, "- orphan"
      assert_includes output, "Summary:   +1  -1  =0"
    end

    test "to_console notes when prune is disabled" do
      output = sync(
        registry: registry("keeper"),
        flipper: FakeFlipper.new(["keeper"]),
        prune: false
      ).to_console

      assert_includes output, "prune disabled"
    end

    test "prune_default honours FEATURE_FLAGS_PRUNE" do
      assert Synchronizer.prune_default

      %w[false 0 no FALSE No].each do |value|
        with_prune_env(value) { assert_not Synchronizer.prune_default, "expected #{value.inspect} to disable prune" }
      end

      with_prune_env("true") { assert Synchronizer.prune_default }
    end

    private def with_prune_env(value)
      previous = ENV["FEATURE_FLAGS_PRUNE"]
      ENV["FEATURE_FLAGS_PRUNE"] = value
      yield
    ensure
      ENV["FEATURE_FLAGS_PRUNE"] = previous
    end
  end
end
