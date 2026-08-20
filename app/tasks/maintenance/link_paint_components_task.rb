# frozen_string_literal: true

module Maintenance
  # Writes down which game-file record a paint corresponds to, so the match is
  # derived once instead of recomputed by everything that needs it.
  #
  # Re-runnable: matching is name-based and improves as names are corrected, so
  # a paint that found nothing last time may find something now.
  class LinkPaintComponentsTask < MaintenanceTasks::Task
    def collection
      Component.where(category: "paints").where.not(name: [nil, ""]).order(:id)
    end

    def count
      collection.count
    end

    def process(component)
      paint = matcher.call(component)

      return if paint.nil?
      return if paint.component_id == component.id

      paint.update!(component_id: component.id)
    end

    # Every ModelPaint is read once to build the index, so it is held for the
    # length of the run rather than rebuilt per component.
    private def matcher
      @matcher ||= PaintComponentMatcher.new
    end
  end
end
