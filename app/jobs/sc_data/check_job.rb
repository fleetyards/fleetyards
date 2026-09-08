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
    VERSIONED_CATALOGUES = [ComponentBuild, CommodityBuild, EquipmentBuild].freeze

    # Bounded on purpose. Should the export stop shipping one of those
    # catalogues for good, an open-ended coverage check would reload the whole
    # of sc_data every night rather than leave the gap for someone to look at.
    MAX_IMPORTS_PER_VERSION = 2

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

    # A version names its environment -- `4.10.1-ptu.12578875` -- so it is
    # already unique across sources and the ledger needs no environment of its
    # own to be asked this per source.
    private def loaded?(source)
      imports = Imports::ScData::AllImport.finished.where(version: source.version).count

      return false if imports.zero?
      return true if imports >= MAX_IMPORTS_PER_VERSION

      VERSIONED_CATALOGUES.all? { |catalogue| catalogue.current(source).exists? }
    end
  end
end
