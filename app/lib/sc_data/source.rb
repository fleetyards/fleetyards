# frozen_string_literal: true

module ScData
  # Which build of the game data the application is reading: the version that
  # marks a catalogue row as current, and the parsed tree a loader reads from.
  #
  # Both come from `config/app/sc_data.yml`, rewritten by `bin/scdata parse`.
  # Asking here rather than reaching into `Rails.configuration` from a model or a
  # job keeps that to one place -- which is what makes it possible to answer the
  # question per request, or per job, once more than one build is available at a
  # time.
  #
  # Deliberately not memoized. The value is a config read, and a process that
  # reparses mid-run (`bin/scdata`) has to see the version it just wrote.
  class Source
    class << self
      def current
        config = Rails.configuration.sc_data

        new(version: config[:version], environment: config[:environment])
      end

      delegate :version, :environment, to: :current
    end

    attr_reader :version, :environment

    def initialize(version:, environment:)
      @version = version
      @environment = environment
    end

    def ==(other)
      other.is_a?(self.class) && other.version == version && other.environment == environment
    end
    alias_method :eql?, :==

    def hash
      [version, environment].hash
    end

    def to_s
      "#{version} (#{environment})"
    end
  end
end
