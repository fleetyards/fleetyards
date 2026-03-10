# frozen_string_literal: true

module Maintenance
  class MigrateModelModulePackageUploadsTask < MaintenanceTasks::Task
    include CarrierwaveToActiveStorageMigration

    MODEL = ModelModulePackage
    FIELD_MAPPINGS = {
      store_image: :new_store_image,
      top_view: :new_top_view,
      side_view: :new_side_view,
      angled_view: :new_angled_view
    }.freeze
  end
end
