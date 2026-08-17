# frozen_string_literal: true

module Maintenance
  # Paints came to FleetYards from RSI long before the game files were parsed,
  # so the artwork sits on a ModelPaint while the component the export creates
  # has none. This carries it across.
  #
  # Which paint belongs to which component is read from the link rather than
  # matched here -- run LinkPaintComponentsTask first. Names are a guess and
  # the link is a decision, so the guess is made in one place and recorded.
  class CopyPaintStoreImagesTask < MaintenanceTasks::Task
    def collection
      ModelPaint.where.not(component_id: nil).order(:id)
    end

    def count
      collection.count
    end

    def process(paint)
      return unless paint.store_image.attached?

      component = paint.component

      # Never overwrite what an admin or the hangar sync put there. A component
      # that already has a picture is curated by definition.
      return if component.nil? || component.store_image.attached?

      # Copied rather than attached by blob: the two records would otherwise
      # share one, and purging the paint would take the component's picture
      # with it -- exactly what consolidating model_paints away would do.
      paint.store_image.blob.open do |file|
        component.store_image.attach(
          io: file,
          filename: paint.store_image.filename.to_s,
          content_type: paint.store_image.content_type
        )
      end
    end
  end
end
