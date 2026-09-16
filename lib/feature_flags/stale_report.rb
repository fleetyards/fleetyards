# frozen_string_literal: true

module FeatureFlags
  # The flags that are on for everyone and have been for long enough to be worth
  # removing.
  #
  # "On for everyone" is asked of Flipper rather than of the change log, because
  # Flipper is what the app actually evaluates -- a gap in the log must not be
  # able to hide an open flag. The log is asked only *since when*, which is the
  # one thing Flipper cannot answer: a disable deletes the gate row, so
  # `flipper_gates.created_at` means "last switched on, if untouched since".
  #
  # `permanent` flags are skipped. They are long-lived infrastructure gates -- the
  # OAuth providers -- and being open for a year is the point rather than a
  # symptom.
  class StaleReport
    DEFAULT_THRESHOLD_DAYS = 30

    Entry = Data.define(:name, :fully_on_since, :days_open) do
      def unknown? = fully_on_since.nil?
    end

    def initialize(threshold_days: DEFAULT_THRESHOLD_DAYS, registry: Registry.load, flipper: Flipper, now: Time.current)
      @threshold_days = threshold_days
      @registry = registry
      @flipper = flipper
      @now = now
    end

    # Oldest first: the flag that has been open longest is the one to remove
    # next. A flag with no recorded history sorts last and is still listed --
    # saying "open, age unknown" beats leaving it out of a report whose whole job
    # is to notice open flags.
    def entries
      open_flags.filter_map { |name| entry_for(name) }
        .sort_by { |entry| entry.days_open || -1 }
        .reverse
    end

    def to_console
      stale = entries
      title = "Flags open for more than #{threshold_days} days"

      [
        title,
        "=" * title.length,
        "",
        stale.empty? ? "  (none)" : stale.map { |entry| line_for(entry) }.join("\n"),
        "",
        "#{stale.size} of #{open_flags.size} fully open flags, #{permanent_count} permanent flags skipped."
      ].join("\n")
    end

    private

    attr_reader :threshold_days, :registry, :flipper, :now

    def open_flags
      @open_flags ||= flipper.features
        .select { |feature| feature.state == :on }
        .map { |feature| feature.name.to_s }
        .reject { |name| permanent?(name) }
        .sort
    end

    def entry_for(name)
      since = FeatureFlagChange.fully_on_since(name)
      days = since && ((now - since) / 1.day).floor

      return Entry.new(name: name, fully_on_since: nil, days_open: nil) if since.nil?
      return if days < threshold_days

      Entry.new(name: name, fully_on_since: since, days_open: days)
    end

    def line_for(entry)
      return "  #{entry.name.ljust(26)} open since an unrecorded date" if entry.unknown?

      "  #{entry.name.ljust(26)} #{entry.days_open} days, since #{entry.fully_on_since.to_date}"
    end

    def permanent?(name)
      registry.fetch(name)&.permanent?
    end

    def permanent_count
      flipper.features.count { |feature| permanent?(feature.name.to_s) }
    end
  end
end
