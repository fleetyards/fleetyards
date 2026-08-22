# frozen_string_literal: true

module FeatureFlags
  # Reconciles Flipper's known features with the YAML registry:
  #
  #   * flags in the registry but missing in Flipper are added
  #   * flags in Flipper but absent from the registry are removed (prune)
  #   * the self-service scope of a flag that already has a FeatureSetting is
  #     brought in line with the registry
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

      reconcile_self_service_scopes

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

    # Whether a flag may be toggled outside /admin/features is the admin UI's
    # call alone. Sync never writes `self_service` and never creates a row to
    # carry one: an admin flipping the toggle there creates the row, and a deploy
    # has no business overruling them in either direction.
    #
    # The scope is not a rollout decision — it says which surface the code reads
    # the flag from, so a release that moves a flag from personal settings to a
    # fleet's has to take effect rather than wait for an admin. Existing rows
    # only, for the same reason: a flag nobody has switched on has no setting to
    # correct, and the admin UI seeds the scope from the registry when it creates
    # one.
    def reconcile_self_service_scopes
      scoped = registry.definitions.select(&:self_service_scope).index_by(&:name)
      return if scoped.empty?

      FeatureSetting.where(feature_name: scoped.keys).find_each do |setting|
        setting.update!(self_service_scope: scoped.fetch(setting.feature_name).self_service_scope)
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
