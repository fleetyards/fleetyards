# frozen_string_literal: true

module Maintenance
  class MigrateHangarImportUploadsTask < MaintenanceTasks::Task
    include CarrierwaveToActiveStorageMigration

    MODEL = Imports::HangarImport
    FIELD_MAPPINGS = {
      import: :new_import
    }.freeze
  end
end
