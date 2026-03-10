# frozen_string_literal: true

module Maintenance
  class MigrateModelPaintUploadsTask < MaintenanceTasks::Task
    include CarrierwaveToActiveStorageMigration

    MODEL = ModelPaint
    FIELD_MAPPINGS = {
      store_image: :new_store_image,
      rsi_store_image: :new_rsi_store_image,
      fleetchart_image: :new_fleetchart_image,
      top_view: :new_top_view,
      side_view: :new_side_view,
      angled_view: :new_angled_view
    }.freeze
  end
end
