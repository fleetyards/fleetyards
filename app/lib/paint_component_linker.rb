# frozen_string_literal: true

# Paints came to FleetYards from RSI long before the game files were parsed,
# so the artwork sits on a ModelPaint while the component the export creates
# has none. This writes down which component each paint is, then carries the
# artwork across.
#
# Re-runnable: matching is name-based and improves as names are corrected, so
# a component that found nothing last time may find something now, and a paint
# whose artwork arrived after its link still gets it copied.
class PaintComponentLinker
  def run
    link
    copy_store_images
  end

  def link
    matcher = PaintComponentMatcher.new

    Component.where(category: "paints").where.not(name: [nil, ""]).find_each do |component|
      paint = matcher.call(component)

      next if paint.nil? || paint.component_id == component.id

      paint.update!(component_id: component.id)
    end
  end

  # Never overwrites what an admin or the hangar sync put there: a component
  # that already has a picture is curated by definition.
  def copy_store_images
    pictured = Component.joins(:store_image_attachment).select(:id)

    ModelPaint.where.not(component_id: nil)
      .where.not(component_id: pictured)
      .joins(:store_image_attachment)
      .includes(:component, store_image_attachment: :blob)
      .find_each { |paint| copy_store_image(paint) }
  end

  # Copied rather than attached by blob: the two records would otherwise share
  # one, and purging the paint would take the component's picture with it.
  private def copy_store_image(paint)
    paint.store_image.blob.open do |file|
      paint.component.store_image.attach(
        io: file,
        filename: paint.store_image.filename.to_s,
        content_type: paint.store_image.content_type
      )
    end
  rescue ActiveStorage::FileNotFoundError => e
    Rails.logger.warn("[paints] #{paint.id} has no stored file to copy: #{e.message}")
  end
end
