# frozen_string_literal: true

module FeatureFlags
  # Reconciles Flipper's known features with the YAML registry:
  #
  #   * flags in the registry but missing in Flipper are added
  #   * flags in Flipper but absent from the registry are removed (prune)
  #   * flags declared `self_service: true` get their FeatureSetting seeded
  #
  # Pruning removes the flag along with all of its gate values, which is what
  # makes the registry authoritative. FEATURE_FLAGS_PRUNE=false disables removal
  # for a single run as an emergency brake.
  class Synchronizer
    Result = Struct.new(:added, :removed, :unchanged, :dry_run, :pruned) do
      def changed?
        added.any? || removed.any?
      end

      def to_console
        title = dry_run ? "Feature flag sync — DRY RUN (no changes made)" : "Feature flag sync — applied"
        prune_note = pruned ? "" : " — skipped, prune disabled"

        [
          title,
          "=" * title.length,
          section("Added", added, "+"),
          section("Removed#{prune_note}", removed, "-"),
          "",
          "Unchanged: #{unchanged.size}",
          "Summary:   +#{added.size}  -#{removed.size}  =#{unchanged.size}"
        ].join("\n")
      end

      private def section(label, names, marker)
        lines = ["", "#{label} (#{names.size})"]
        lines.concat(names.empty? ? ["  (none)"] : names.map { |name| "  #{marker} #{name}" })
        lines.join("\n")
      end
    end

    # Pruning is on by default; FEATURE_FLAGS_PRUNE=false turns it off.
    def self.prune_default
      !%w[false 0 no].include?(ENV["FEATURE_FLAGS_PRUNE"].to_s.strip.downcase)
    end

    def initialize(registry: Registry.load, flipper: Flipper, prune: self.class.prune_default, dry_run: false)
      @registry = registry
      @flipper = flipper
      @prune = prune
      @dry_run = dry_run
    end

    def call
      desired = registry.names
      existing = flipper.features.map(&:key)

      to_add = (desired - existing).sort
      to_remove = prune ? (existing - desired).sort : []

      apply!(to_add, to_remove) unless dry_run
      log_result(to_add, to_remove)

      Result.new(
        added: to_add,
        removed: to_remove,
        unchanged: (desired & existing).sort,
        dry_run: dry_run,
        pruned: prune
      )
    end

    private

    attr_reader :registry, :flipper, :prune, :dry_run

    def apply!(to_add, to_remove)
      to_add.each { |name| flipper.add(name) }

      seed_self_service_settings

      return unless prune

      to_remove.each { |name| flipper.remove(name) }

      # The self-service setting has to go with the flag. Nothing else deletes
      # these rows, so leaving one behind would silently restore
      # user-toggleability if the flag is ever declared again.
      #
      # Keyed on the registry rather than on to_remove: to_remove is derived
      # from Flipper, so a run interrupted between the two steps above would
      # strand a setting whose feature is already gone — and no later run would
      # ever look at it again, because it is no longer in Flipper to be removed.
      FeatureSetting.where.not(feature_name: registry.names).destroy_all
    end

    # The registry seeds self-service, it does not own it: admins flip it at
    # /admin/features, and a deploy must not undo that. So `self_service` on an
    # existing row is left exactly as it is, and dropping the key from the
    # registry retracts nothing — only removing the flag does, through the prune
    # above.
    #
    # The scope is different: it says which surface reads the flag, which is a
    # property of the code, not a rollout decision. A release that moves a flag
    # from personal settings to a fleet's has to take effect, so it is reconciled
    # on every run.
    def seed_self_service_settings
      registry.definitions.select(&:self_service?).each do |definition|
        setting = FeatureSetting.find_or_initialize_by(feature_name: definition.name) do |new_setting|
          new_setting.self_service = true
        end

        setting.self_service_scope = definition.self_service_scope
        setting.save! if setting.changed?
      end
    end

    def log_result(to_add, to_remove)
      return unless defined?(Rails) && Rails.logger

      Rails.logger.info do
        {event: "feature_flags_sync", dry_run: dry_run, prune: prune, added: to_add, removed: to_remove}.inspect
      end
    end
  end
end
