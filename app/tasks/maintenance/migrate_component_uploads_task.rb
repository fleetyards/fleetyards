# frozen_string_literal: true

module Maintenance
  class MigrateComponentUploadsTask < MaintenanceTasks::Task
    include CarrierwaveToActiveStorageMigration

    MODEL = Component
    FIELD_MAPPINGS = {
      store_image: :new_store_image
    }.freeze
  end
end
