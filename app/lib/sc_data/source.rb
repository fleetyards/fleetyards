# frozen_string_literal: true

module ScData
  # Which build of the game data is being read: the version that marks a
  # catalogue row as current, and the parsed tree a loader reads from.
  #
  # More than one can be configured -- live and ptu carry different builds -- so
  # this answers per request and per job rather than per process. Asking here
  # rather than reaching into `Rails.configuration` from a model or a job is what
  # made that possible without touching the eighty-odd callers.
  class Source
    class << self
      # The source the work in hand is reading: what a request asked for, else
      # the configured default.
      #
      # Deliberately not memoized. The value is a config read, and a process that
      # reparses mid-run (`bin/scdata`) has to see the version it just wrote.
      def current
        ScData::Current.source || default
      end

      def default
        name = config[:default].to_s

        find(name) || configured.first
      end

      # Every source the config declares, in the order it declares them.
      def configured
        config.fetch(:sources, {}).map { |environment, version| new(environment: environment.to_s, version:) }
      end

      def find(environment)
        configured.find { |source| source.environment == environment.to_s }
      end

      # The sources a reader may actually be pointed at: configured, carrying
      # builds, and not behind the default. An environment that has never been
      # loaded would answer every question with nothing, so it is not offered
      # rather than served empty.
      #
      # Behind the default means stale rather than alternative. A ptu cycle ends
      # with live catching up and passing it, and from that moment the ptu tree
      # still sitting there describes an *older* build -- offering it would put
      # last month's data behind a label that promises next month's. So a source
      # is offered while it is ahead, and stops being offered the moment live
      # overtakes it, without anyone having to edit the config.
      def available
        chosen = default

        configured.select do |source|
          source.loaded? && (source == chosen || source.ahead_of?(chosen))
        end
      end

      # Runs a block with a source in force, and puts back whatever was there.
      # Nested so a job inside a request cannot strand the outer value.
      def with(source)
        previous = ScData::Current.source
        ScData::Current.source = source
        yield
      ensure
        ScData::Current.source = previous
      end

      delegate :version, :environment, to: :current

      private def config
        Rails.configuration.sc_data
      end
    end

    # Every catalogue that records what a build said. A source counts as loaded
    # when any of them has a row for it -- the four are loaded separately, and the
    # first to finish makes the source readable.
    BUILDS = [EquipmentBuild, ComponentBuild, CommodityBuild, ModelBuild].freeze

    attr_reader :version, :environment

    def initialize(version:, environment:)
      @version = version
      @environment = environment
    end

    def loaded?
      BUILDS.any? { |klass| klass.where(environment:, version:).exists? }
    end

    def default?
      self == self.class.default
    end

    # Ordered the way the game names a build: `4.10.0-live.12519617` is the
    # version, then the id of the build that carries it.
    #
    # The id is the tiebreak rather than the key, because the case this exists
    # to catch is a live build that has caught up with a finished ptu cycle: same
    # version on both sides, and live's id the higher one. Comparing versions
    # alone would call that a draw and keep offering the ptu tree.
    #
    # A version with no build id -- which is every version a test writes -- sorts
    # as id zero, so the two forms still compare.
    def ahead_of?(other)
      (precedence <=> other.precedence) == 1
    end

    protected def precedence
      release, build = version.to_s.split("-", 2)
      id = build.to_s[/\d+\z/].to_i

      [Gem::Version.correct?(release) ? Gem::Version.new(release) : Gem::Version.new(0), id]
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
