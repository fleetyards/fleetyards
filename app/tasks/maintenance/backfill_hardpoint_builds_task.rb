# frozen_string_literal: true

module Maintenance
  # Seeds a `HardpointBuild` from what each game-file slot already says, so the
  # table is populated before anything reads it rather than staying empty until
  # the next sc_data load.
  #
  # A task rather than a data migration: 22,561 slots at one lookup and one
  # insert each took two minutes when this was measured, and `bin/deploy-release`
  # runs `data:migrate` inside the Kamal pre-deploy hook -- so as a migration it
  # would block every deploy behind it, and a hook that retries three times would
  # re-scan the whole table each attempt. Here it is triggered once, watched, and
  # resumable.
  #
  # Only the `game_files` half. The ship matrix comes from no build and has no
  # version, so giving it rows would make "has a build row" stop meaning "this
  # build describes it".
  #
  # Which build do the current columns describe? Whichever load ran last, which
  # is the configured source: `persist_loadout` destroys every game-file row a
  # run did not touch, so what survives on the table is what the last load wrote.
  # That premise holds only while nothing can load a second environment, which is
  # item 3 of docs/exec-plans/sc-data-live-and-ptu.md -- and item 3 is gated on
  # this work, so the two cannot cross.
  #
  # Re-runnable and additive: it creates or updates the row for the source in
  # force and deletes nothing. No `dry_run` attribute on purpose -- one that
  # defaults to true makes a console run roll back silently while still reporting
  # "succeeded", and there is nothing here to rehearse.
  class BackfillHardpointBuildsTask < MaintenanceTasks::Task
    def collection
      Hardpoint.where(source: :game_files)
    end

    def count
      collection.count
    end

    def process(hardpoint)
      build = hardpoint.builds.find_or_initialize_by(
        environment: source.environment, version: source.version
      )

      # Assigned through the model rather than written raw, because the enums and
      # the serialized arrays have to go back through the build's own casters:
      # `hardpoint.group` hands back "weapons" and the build stores 40.
      build.assign_attributes(
        HardpointBuild::FACTS.index_with { |fact| hardpoint.public_send(fact) }
      )

      return unless build.changed?

      # Validation is skipped because the uniqueness check it would run is the
      # unique index's job here, and 22k extra selects buy nothing.
      build.save!(validate: false)
    end

    # Read once for the run rather than per slot: `ScData::Source.current` is a
    # config read on every call, deliberately unmemoized there.
    private def source
      @source ||= ::ScData::Source.current
    end
  end
end
