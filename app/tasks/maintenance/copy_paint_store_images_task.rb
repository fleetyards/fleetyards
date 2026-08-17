# frozen_string_literal: true

module Maintenance
  # Paints came to FleetYards from RSI long before the game files were parsed,
  # so the artwork sits on a ModelPaint while the component the export creates
  # has none. This carries it across for the ones that can be matched.
  #
  # The collection is every named paint component rather than only those
  # missing a picture: attaching one would otherwise move a record out of
  # scope mid-run, and a stable collection is what makes the task resumable.
  class CopyPaintStoreImagesTask < MaintenanceTasks::Task
    def collection
      Component.where(category: "paints").where.not(name: [nil, ""]).order(:id)
    end

    def count
      collection.count
    end

    def process(component)
      # Never overwrite what an admin or the hangar sync put there. A component
      # that already has a picture is curated by definition.
      return if component.store_image.attached?

      paint = matcher.call(component)

      return if paint.nil?
      return unless paint.store_image.attached?

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

    # Every ModelPaint is read once to build the index, so it is held for the
    # length of the run rather than rebuilt per component.
    private def matcher
      @matcher ||= PaintComponentMatcher.new
    end
  end
end
