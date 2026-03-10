# frozen_string_literal: true

module Maintenance
  class MigrateModelUploadsTask < MaintenanceTasks::Task
    include CarrierwaveToActiveStorageMigration

    MODEL = Model
    FIELD_MAPPINGS = {
      store_image: :new_store_image,
      rsi_store_image: :new_rsi_store_image,
      fleetchart_image: :new_fleetchart_image,
      top_view: :new_top_view,
      side_view: :new_side_view,
      front_view: :new_front_view,
      angled_view: :new_angled_view,
      top_view_colored: :new_top_view_colored,
      side_view_colored: :new_side_view_colored,
      front_view_colored: :new_front_view_colored,
      angled_view_colored: :new_angled_view_colored,
      brochure: :new_brochure,
      holo: :new_holo
    }.freeze
  end
end
