# frozen_string_literal: true

require "test_helper"

module FeatureFlags
  class RegistryTest < ActiveSupport::TestCase
    # Flags a data migration created that have since been retired on purpose:
    # dropped from the registry so the next sync prunes them from Flipper.
    # Listing one here is what tells a deliberate retirement apart from an
    # entry accidentally left out, which is all the guard below can see.
    RETIRED_FLAG_NAMES = %w[hardpoints-v2].freeze

    def registry(raw)
      Registry.new(raw: raw)
    end

    test "accepts a minimal valid entry" do
      assert_empty registry("my_flag" => {"description" => "Does a thing"}).validation_errors
    end

    test "exposes definitions and names" do
      definitions = registry(
        "b_flag" => {"description" => "B"},
        "a_flag" => {"description" => "A", "permanent" => true}
      ).definitions

      assert_equal %w[b_flag a_flag], definitions.map(&:name)
      assert_equal "B", definitions.first.description
      assert_predicate definitions.last, :permanent?
      assert_not_predicate definitions.first, :permanent?
    end

    test "fetch finds a definition by name" do
      assert_equal "Does a thing", registry("my_flag" => {"description" => "Does a thing"}).fetch(:my_flag).description
      assert_nil registry("my_flag" => {"description" => "x"}).fetch("nope")
    end

    test "requires a description" do
      errors = registry("my_flag" => {}).validation_errors

      assert_includes errors.join, "missing required key 'description'"
    end

    test "treats a blank description as missing" do
      errors = registry("my_flag" => {"description" => "   "}).validation_errors

      assert_includes errors.join, "missing required key 'description'"
    end

    test "rejects unknown keys" do
      errors = registry("my_flag" => {"description" => "x", "owner" => "@someone"}).validation_errors

      assert_includes errors.join, %(unknown keys ["owner"])
    end

    test "rejects a non-boolean permanent" do
      errors = registry("my_flag" => {"description" => "x", "permanent" => "yes"}).validation_errors

      assert_includes errors.join, "permanent must be a boolean"
    end

    test "reads self_service, defaulting to off" do
      definitions = registry(
        "plain" => {"description" => "A"},
        "toggleable" => {"description" => "B", "self_service" => "user"}
      ).definitions

      assert_not_predicate definitions.first, :self_service?
      assert_nil definitions.first.self_service_scope
      assert_predicate definitions.last, :self_service?
      assert_predicate definitions.last, :self_service_user?
    end

    test "reads the fleet self_service scope" do
      definition = registry("fleet_flag" => {"description" => "A", "self_service" => "fleet"}).fetch("fleet_flag")

      assert_predicate definition, :self_service?
      assert_predicate definition, :self_service_fleet?
      assert_not_predicate definition, :self_service_user?
      assert_equal "fleet", definition.self_service_scope
    end

    test "treats self_service true as the user scope" do
      definition = registry("legacy" => {"description" => "A", "self_service" => true}).fetch("legacy")

      assert_predicate definition, :self_service_user?
      assert_equal "user", definition.self_service_scope
    end

    test "treats self_service false as no toggle" do
      definition = registry("plain" => {"description" => "A", "self_service" => false}).fetch("plain")

      assert_not_predicate definition, :self_service?
      assert_empty registry("plain" => {"description" => "A", "self_service" => false}).validation_errors
    end

    test "self_service selects the definitions for one scope" do
      subject = registry(
        "personal" => {"description" => "A", "self_service" => "user"},
        "fleet_wide" => {"description" => "B", "self_service" => "fleet"},
        "admin_only" => {"description" => "C"}
      )

      assert_equal %w[personal], subject.self_service("user").map(&:name)
      assert_equal %w[fleet_wide], subject.self_service("fleet").map(&:name)
    end

    test "rejects an unknown self_service scope" do
      errors = registry("my_flag" => {"description" => "x", "self_service" => "squadron"}).validation_errors

      assert_includes errors.join, "self_service must be one of"
    end

    test "allows hyphens so the oauth provider gates stay valid" do
      assert_empty registry("oauth-discord" => {"description" => "Discord login"}).validation_errors
    end

    test "rejects names that are not lowercase" do
      errors = registry("MyFlag" => {"description" => "x"}).validation_errors

      assert_includes errors.join, "name must match"
    end

    test "rejects names starting with a non-letter" do
      errors = registry("1flag" => {"description" => "x"}).validation_errors

      assert_includes errors.join, "name must match"
    end

    test "rejects overly long names" do
      errors = registry(("a" * (Registry::MAX_NAME_LENGTH + 1)) => {"description" => "x"}).validation_errors

      assert_includes errors.join, "exceeds #{Registry::MAX_NAME_LENGTH} characters"
    end

    test "rejects attributes that are not a mapping" do
      errors = registry("my_flag" => "nope").validation_errors

      assert_includes errors.join, "attributes must be a mapping"
    end

    test "rejects a root that is not a mapping" do
      errors = registry([]).validation_errors

      assert_includes errors.join, "root must be a mapping"
    end

    test "validate! raises with every problem listed" do
      error = assert_raises(Registry::InvalidRegistryError) do
        registry("Bad Name" => {}, "other" => {"description" => "x", "nope" => 1}).validate!
      end

      assert_includes error.message, "name must match"
      assert_includes error.message, "missing required key 'description'"
      assert_includes error.message, "unknown keys"
    end

    test "validate! returns self when valid" do
      subject = registry("my_flag" => {"description" => "x"})

      assert_same subject, subject.validate!
    end

    test "the checked-in registry is valid" do
      assert_empty Registry.new.validation_errors
    end

    test "the checked-in registry covers every flag created by a data migration" do
      missing = migration_flag_names - Registry.new.names - RETIRED_FLAG_NAMES

      assert_empty missing,
        "flags created by data migrations but missing from config/feature_flags.yml (sync would prune them). " \
        "Retiring one on purpose? Add it to RETIRED_FLAG_NAMES."
    end

    test "a flag listed as retired is really gone from the registry" do
      assert_empty RETIRED_FLAG_NAMES & Registry.new.names,
        "declared again in config/feature_flags.yml — drop it from RETIRED_FLAG_NAMES so the guard sees it"
    end

    test "the migration scan finds both the literal and %w forms" do
      # Guards the heuristic below: if it silently stopped matching, the test
      # above would pass by finding nothing rather than by the registry being
      # complete.
      names = migration_flag_names

      assert_includes names, "fleet_logistics", "expected the Flipper.add(\"…\") form to be found"
      assert_includes names, "oauth-discord", "expected the %w[…] loop form to be found"
      assert_operator names.size, :>=, 13
    end

    # Data migrations create flags either as Flipper.add("name") or by looping
    # over a %w[] array, so both shapes have to be scanned.
    private def migration_flag_names
      Dir[Rails.root.join("db/data/*.rb")].filter_map { |path|
        source = File.read(path)
        next unless source.include?("Flipper.add")

        source.scan(/Flipper\.add\(\s*["']([^"']+)["']\s*\)/).flatten +
          source.scan(/%w\[([^\]]*)\]/).flatten.flat_map(&:split)
      }.flatten.uniq
    end
  end
end
