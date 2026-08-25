# frozen_string_literal: true

module ScData
  class CheckJob < ApplicationJob
    # Every catalogue BaseLoader.all fills that stamps the build it was last
    # seen in. A finished import on its own is not proof the current build was
    # fully loaded: a loader added to BaseLoader.all after that import ran would
    # never get a chance, because the version it waits on has already been
    # imported. Commodity and Equipment sat empty for a week that way.
    VERSIONED_CATALOGUES = [Component, Commodity, Equipment].freeze

    # Bounded on purpose. Should the export stop shipping one of those
    # catalogues for good, an open-ended coverage check would reload the whole
    # of sc_data every night rather than leave the gap for someone to look at.
    MAX_IMPORTS_PER_VERSION = 2

    def perform
      new_version = ::ScData::Source.version

      return if new_version.blank?
      return if loaded?(new_version)

      Loaders::ScData::AllJob.perform_async(new_version)
    end

    private def loaded?(version)
      imports = Imports::ScData::AllImport.finished.where(version:).count

      return false if imports.zero?
      return true if imports >= MAX_IMPORTS_PER_VERSION

      VERSIONED_CATALOGUES.all? { |catalogue| catalogue.exists?(version:) }
    end
  end
end
