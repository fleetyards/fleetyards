# frozen_string_literal: true

module Maintenance
  class MigrateManufacturerUploadsTask < MaintenanceTasks::Task
    include CarrierwaveToActiveStorageMigration

    MODEL = Manufacturer
    FIELD_MAPPINGS = {
      logo: :new_logo
    }.freeze
  end
end
