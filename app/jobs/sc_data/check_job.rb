# frozen_string_literal: true

module ScData
  class CheckJob < ApplicationJob
    # Every catalogue `BaseLoader.all` fills that records a build. A finished
    # import on its own is not proof the build was fully loaded: a loader added
    # to `BaseLoader.all` after that import ran would never get a chance,
    # because the version it waits on has already been imported. Commodity and
    # Equipment sat empty for a week that way.
    #
    # The build rows rather than the catalogues' own `version` columns. Those
    # columns are shared between environments and a load rewrites every one of
    # them, so after a ptu load `Component.exists?(version: <live>)` is false
    # and this would re-enqueue a live load it did not need.
    #
    # `BlueprintBuild` was missing here until the tree checksum went in, which
    # is the same hole this comment already describes: blueprints arrived after
    # the build they shipped on had been imported, so nothing would have noticed
    # had their loader never run. Every build model `BaseLoader.all` fills
    # belongs in this list.
    VERSIONED_CATALOGUES = [ComponentBuild, CommodityBuild, EquipmentBuild, BlueprintBuild].freeze

    # Bounded on purpose. Should the export stop shipping one of those
    # catalogues for good, an open-ended coverage check would reload the whole
    # of sc_data every night rather than leave the gap for someone to look at.
    #
    # Per *tree*, not per version, and that distinction is load-bearing. A
    # tree-driven reload writes a finished import too, so counting them by
    # version let one of those burn the coverage budget: live sits on a build
    # with one import, the first checksum reload makes two, and from then on the
    # ceiling short-circuits `VERSIONED_CATALOGUES` for that build entirely.
    # Add a loader after that and nothing reloads -- the tree is byte-identical
    # so the checksum cannot see it, and the check that could is unreachable.
    # Which is exactly how Commodity and Equipment sat empty for a week.
    #
    # A new tree is a new thing to try, so it starts the count again.
    MAX_IMPORTS_PER_TREE = 2

    # Every configured source, not only the default one. Otherwise a ptu build
    # reaches the bucket and the config and then nothing ever loads it, which is
    # quiet rather than loud.
    def perform
      ::ScData::Source.configured.each do |source|
        next if source.version.blank?
        next if loaded?(source)

        Loaders::ScData::AllJob.perform_async(source.version, nil, source.environment)
      end
    end

    # Three questions, and a load runs if any of them answers no.
    #
    # A version names its environment -- `4.10.1-ptu.12578875` -- so it is
    # already unique across sources and the ledger needs no environment of its
    # own to be asked this per source.
    private def loaded?(source)
      last = Imports::ScData::AllImport.last_finished_for(source)

      return false if last.blank?
      return false if tree_changed?(source, last)

      # Only the coverage check below is bounded; the tree check above is not a
      # guess and needs no ceiling.
      return true if attempts_at(source, last.tree_checksum) >= MAX_IMPORTS_PER_TREE

      VERSIONED_CATALOGUES.all? { |catalogue| catalogue.current(source).exists? }
    end

    # How many times the loaders have been given this tree. Falls back to the
    # whole version for a load recorded before checksums existed -- there is no
    # tree to count by, and counting none would leave the coverage check
    # unbounded, which is the thing the ceiling exists to prevent.
    private def attempts_at(source, checksum)
      scope = Imports::ScData::AllImport.finished.where(version: source.version)

      return scope.count if checksum.blank?

      scope.where("input ->> 'tree_checksum' = ?", checksum).count
    end

    # Whether the bucket holds a different tree than the one that load read.
    #
    # This is the question the version could never answer. A parser change
    # rewrites the tree and leaves the version alone, so keying on the version
    # meant a pushed re-parse reached nobody until a human triggered a load --
    # which is how Commodity and Equipment sat empty for a week.
    #
    # Fails closed. If the bucket cannot be reached, or is not configured at
    # all -- a developer with the tree on disk and no credentials -- the answer
    # is "no change", because reloading the whole of sc_data on a network blip
    # is far worse than waiting for the next run.
    private def tree_changed?(source, import)
      remote = remote_checksum(source)

      return false if remote.blank?

      remote != import.tree_checksum
    end

    private def remote_checksum(source)
      return unless ::ScData::ParsedStore.configured?

      ::ScData::ParsedStore.new(source.environment).remote_checksum
    rescue => e
      Rails.logger.warn("[sc_data] CheckJob could not read the tree for #{source}: #{e.message}")

      nil
    end
  end
end
