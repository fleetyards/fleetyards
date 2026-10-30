# frozen_string_literal: true

# Paints came to FleetYards from RSI long before the game files were parsed,
# so the artwork sits on a ModelPaint while the component the export creates
# has none. This writes down which component each paint is, then carries the
# artwork across.
#
# Re-runnable: matching is name-based and improves as names are corrected, so
# a paint that found nothing last time may find something now, and a paint
# whose artwork arrived after its link still gets it copied.
class PaintComponentLinker
  def run
    link
    copy_store_images
  end

  # A link, once written, stays: names are a guess, and two components can
  # read as the same paint -- the Aurora Mk I and Mk II Foundation Fest
  # liveries both match one -- so moving it whenever another claimant comes
  # along would flip it on every run. Only a paint with no link, or one whose
  # component the build dropped, is linked again.
  def link
    matcher = PaintComponentMatcher.new
    current = Component.where(category: "paints").where.not(name: [nil, ""]).joins(:build)
    current_ids = current.pluck(:id).to_set

    current.find_each do |component|
      paint = matcher.call(component)

      next if paint.nil? || current_ids.include?(paint.component_id)

      paint.update!(component_id: component.id)
    rescue => e
      report(e, "component #{component.id} could not be linked")
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
  rescue => e
    report(e, "paint #{paint.id} artwork could not be copied")
  end

  # One bad row must not leave every row after it unlinked.
  private def report(error, message)
    Appsignal.report_error(error)
    Rails.logger.error("[#{self.class.name}] #{message}: #{error.class}: #{error.message}")
  end
end
