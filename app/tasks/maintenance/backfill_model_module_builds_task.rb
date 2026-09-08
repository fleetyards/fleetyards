# frozen_string_literal: true

module Maintenance
  # Seeds a `ModelModuleBuild` from what each keyed module already says, so the
  # table is populated before anything reads it rather than staying empty until
  # the next sc_data load.
  #
  # Only modules with an `sc_key`: the loader walks no others, so no build has an
  # opinion about them. `ModelModule.in_build` leaves those alone by the same
  # rule -- they are the RSI-store modules Fleetyards knows about and the game
  # files do not.
  #
  # Which build do the current columns describe? Whichever load ran last, which
  # is the configured source. A task rather than a data migration, for the reason
  # `BackfillHardpointBuildsTask` records: `bin/deploy-release` runs
  # `data:migrate` inside the Kamal pre-deploy hook.
  #
  # Re-runnable and additive, and no `dry_run` attribute -- one defaulting to
  # true makes a console run roll back silently while still reporting
  # "succeeded", and there is nothing here to rehearse.
  class BackfillModelModuleBuildsTask < MaintenanceTasks::Task
    def collection
      ModelModule.where.not(sc_key: nil)
    end

    def count
      collection.count
    end

    def process(model_module)
      build = model_module.builds.find_or_initialize_by(
        environment: source.environment, version: source.version
      )

      build.assign_attributes(ModelModuleBuild.facts_from(model_module))

      return unless build.changed?

      build.save!(validate: false)
    end

    # Read once for the run rather than per module: `ScData::Source.current` is a
    # config read on every call, deliberately unmemoized there.
    private def source
      @source ||= ::ScData::Source.current
    end
  end
end
