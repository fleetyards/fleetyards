# frozen_string_literal: true

module ScData
  # What CI keys its parsed-tree cache on: one fragment per configured source,
  # naming the tree that source is on rather than the build it was parsed from.
  #
  # A class rather than a few lines in `bin/scdata` because it gates every
  # `ruby-tests` run. The step it replaced was a local YAML read that could not
  # fail, and the behaviour that matters here is what happens when the bucket
  # cannot be reached -- which is not reachable from a test if it lives in a
  # shell script.
  class CacheKey
    Result = Struct.new(:fragments, :warnings) do
      def key
        fragments.join("_")
      end

      def empty?
        fragments.empty?
      end
    end

    def self.call(...) = new(...).call

    def initialize(settings: nil)
      @settings = settings
    end

    def call
      warnings = []

      fragments = ::ScData::Source.configured.filter_map do |source|
        next if source.version.blank?

        checksum = checksum_for(source, warnings)

        "#{source.environment}-#{checksum || source.version}"
      end

      Result.new(fragments, warnings)
    end

    # Falls back to the version, which is what the key held before any of this,
    # so a bucket that blinks costs a stale cache entry rather than a red run on
    # every open pull request -- including the ones whose cache would have hit
    # and needed no network at all.
    private def checksum_for(source, warnings)
      ::ScData::ParsedStore.new(source.environment, settings: @settings).remote_checksum
    rescue => e
      warnings << "Could not read the #{source.environment} tree (#{e.class}); keying on the version."

      nil
    end
  end
end
