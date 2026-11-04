# frozen_string_literal: true

# Measures how wide a ship's angled fleetchart pictures are, from its outline in the
# top view. The angled cameras only turn and tilt, so a point's horizontal place in
# those pictures depends on nothing but where it is seen from above.
class FleetchartTopViewAnalyzer < ActiveStorage::Analyzer::ImageAnalyzer::Vips
  TOP_VIEW_NAMES = %w[
    top_view top_view_colored extended_top_view extended_top_view_colored landed_top_view landed_top_view_colored
  ].freeze

  # Fitted to the shape of all angled pictures against their ships' outlines.
  ANGLED_YAW = 45.0
  ANGLED_REAR_YAW = -51.5

  MEASURED_SIZE = 640
  OPAQUE = 64

  def self.accept?(blob)
    super && blob.attachments.any? { |attachment| attachment.record_type == "Model" && TOP_VIEW_NAMES.include?(attachment.name) }
  end

  def metadata
    super.merge(outline_extents)
  end

  private def outline_extents
    download_blob_to_tempfile do |file|
      image = ::Vips::Image.thumbnail(file.path, MEASURED_SIZE)

      next {} unless image.has_alpha?

      rows = opaque_rows(image)

      next {} if rows.empty?

      {
        angled_extent: extent_of(rows, ANGLED_YAW, image.width),
        angled_rear_extent: extent_of(rows, ANGLED_REAR_YAW, image.width)
      }
    end
  end

  # The first and last opaque pixel of each row, as nothing between them can be an extreme.
  private def opaque_rows(image)
    alpha = image.extract_band(image.bands - 1).cast(:uchar).write_to_memory.bytes

    alpha.each_slice(image.width).with_index.filter_map do |row, y|
      first = row.index { |value| value > OPAQUE }

      [y, first, row.rindex { |value| value > OPAQUE }] if first
    end
  end

  # As a share of the picture's width, which is the ship's length.
  private def extent_of(rows, yaw, width)
    cosine = Math.cos(yaw * Math::PI / 180)
    sine = Math.sin(yaw * Math::PI / 180)
    places = rows.flat_map { |y, first, last| [first * cosine + y * sine, last * cosine + y * sine] }

    ((places.max - places.min + cosine.abs + sine.abs) / width).round(4)
  end
end
