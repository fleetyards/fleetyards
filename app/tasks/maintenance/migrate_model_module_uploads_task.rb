# frozen_string_literal: true

module Maintenance
  class MigrateModelModuleUploadsTask < MaintenanceTasks::Task
    include CarrierwaveToActiveStorageMigration

    MODEL = ModelModule
    FIELD_MAPPINGS = {
      store_image: :new_store_image
    }.freeze
  end
end
