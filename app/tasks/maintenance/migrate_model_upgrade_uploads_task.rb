# frozen_string_literal: true

module Maintenance
  class MigrateModelUpgradeUploadsTask < MaintenanceTasks::Task
    include CarrierwaveToActiveStorageMigration

    MODEL = ModelUpgrade
    FIELD_MAPPINGS = {
      store_image: :new_store_image
    }.freeze
  end
end
