# frozen_string_literal: true

module Maintenance
  class MigrateImageUploadsTask < MaintenanceTasks::Task
    include CarrierwaveToActiveStorageMigration

    MODEL = Image
    FIELD_MAPPINGS = {
      name: :file
    }.freeze
  end
end
