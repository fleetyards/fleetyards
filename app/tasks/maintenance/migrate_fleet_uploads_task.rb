# frozen_string_literal: true

module Maintenance
  class MigrateFleetUploadsTask < MaintenanceTasks::Task
    include CarrierwaveToActiveStorageMigration

    MODEL = Fleet
    FIELD_MAPPINGS = {
      logo: :new_logo,
      background_image: :new_background_image
    }.freeze
  end
end
