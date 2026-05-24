# frozen_string_literal: true

# == Schema Information
#
# Table name: compare_images
#
#  id         :uuid             not null, primary key
#  slug_set   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_compare_images_on_slug_set  (slug_set) UNIQUE
#
class CompareImage < ApplicationRecord
  has_one_attached :image

  validates :slug_set, presence: true, uniqueness: true

  STYLE_VERSION = "v2"

  def self.for(models)
    models_with_images = models.select { |m| m.store_image.attached? }
    return nil if models_with_images.empty?

    slug_set = "#{STYLE_VERSION}-#{models_with_images.map(&:slug).sort.join("-")}"
    record = find_or_initialize_by(slug_set: slug_set)
    record.generate!(models_with_images) unless record.image.attached?
    record
  end

  def generate!(models)
    buffer = build_composite(models)
    return if buffer.nil?

    image.attach(
      io: StringIO.new(buffer),
      filename: "#{slug_set}.jpg",
      content_type: "image/jpeg"
    )
    save!
  rescue ActiveRecord::RecordNotUnique
    # Another worker created the row between find_or_initialize_by and save.
    # The next request will pick up their attachment from the cache.
  end

  CANVAS_WIDTH = 1200
  CANVAS_HEIGHT = 630
  DIAGONAL_SLANT = 80
  MASK_SUPERSAMPLE = 2

  private def build_composite(models)
    require "vips"

    buffers = models.filter_map { |m| m.store_image.download if m.store_image.attached? }
    return nil if buffers.empty?

    width = CANVAS_WIDTH
    height = CANVAS_HEIGHT
    # Scale the slant down as the slice count grows so narrow slices don't fully overlap.
    slant = [DIAGONAL_SLANT, (width / buffers.size) / 2 - 10].min
    n = buffers.size

    canvas = Vips::Image.black(width, height, bands: 3).copy(interpretation: :srgb).cast(:uchar)

    buffers.each_with_index do |buf, i|
      x_tl = i.zero? ? 0 : (i * width / n) + slant
      x_tr = (i == n - 1) ? width : ((i + 1) * width / n) + slant
      x_bl = i.zero? ? 0 : (i * width / n) - slant
      x_br = (i == n - 1) ? width : ((i + 1) * width / n) - slant

      slice_left = [x_tl, x_bl].min
      slice_right = [x_tr, x_br].max
      slice_w = slice_right - slice_left

      img = Vips::Image.thumbnail_buffer(buf, slice_w, height: height, crop: :centre)
      img = img[0..2] if img.bands > 3
      img = img.colourspace(:srgb).cast(:uchar)

      positioned = img.embed(slice_left, 0, width, height, extend: :black)

      poly = [[x_tl, 0], [x_tr, 0], [x_br, height], [x_bl, height]]
      alpha = diagonal_alpha(width, height, poly).cast(:float) / 255.0
      canvas = (positioned.cast(:float) * alpha + canvas.cast(:float) * (alpha * -1 + 1)).cast(:uchar)
    end

    canvas.jpegsave_buffer(Q: 85)
  end

  private def diagonal_alpha(width, height, polygon)
    sw = width * MASK_SUPERSAMPLE
    sh = height * MASK_SUPERSAMPLE
    pts = polygon.map { |x, y| "#{x * MASK_SUPERSAMPLE},#{y * MASK_SUPERSAMPLE}" }.join(" ")
    svg = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="#{sw}" height="#{sh}" viewBox="0 0 #{sw} #{sh}">
        <polygon points="#{pts}" fill="white"/>
      </svg>
    SVG
    hires = Vips::Image.svgload_buffer(svg)
    hires[hires.bands - 1].resize(1.0 / MASK_SUPERSAMPLE, kernel: :lanczos3)
  end
end
