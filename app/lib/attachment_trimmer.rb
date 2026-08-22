# frozen_string_literal: true

# Views come out of the render pipeline framed loosely: the ship sits inside a
# canvas of transparency, and how much of that canvas is padding differs from
# render to render. Everything downstream reads the padding as part of the hull
# -- the fleetchart sizes each ship from the blob's own width and height -- and
# the four webp representations carry it into every size they build.
#
# So the crop happens once, to the original, before any representation exists.
# Only transparency counts as empty: an image without an alpha channel is left
# alone rather than guessed at from its corner pixel, which would eat into a
# subject that legitimately reaches the frame.
class AttachmentTrimmer
  # A pixel counts as content from alpha 1 up, so a canvas exported with a
  # not-quite-zero transparent border still trims.
  ALPHA_THRESHOLD = 1

  # The views uploaded up to now are already tight against the hull, bar the
  # pixel or two of near-transparency an antialiased edge leaves behind. That is
  # not a border, and cropping it would replace the blob and re-save the record
  # for nothing, so a margin only counts as padding from here out.
  MIN_MARGIN = 2

  def initialize(attachment)
    @attachment = attachment
    @blob = attachment.blob
  end

  # True when the crop replaced the blob, which brings the record's own
  # callback round again on what it attached. False when there was nothing to
  # crop, leaving the caller to carry on with the blob it already has.
  def call
    return false if trimmed?

    buffer = trimmed_buffer

    return mark_trimmed if buffer.nil?

    attach(buffer)
    true
  end

  private

  attr_reader :attachment, :blob

  def trimmed?
    blob.metadata[:trimmed].present?
  end

  def trimmed_buffer
    return if ActiveStorageVariants::VECTOR_CONTENT_TYPES.include?(blob.content_type)

    require "vips"

    image = Vips::Image.new_from_buffer(blob.download, "")
    return unless image.has_alpha?

    left, top, width, height = image[image.bands - 1]
      .find_trim(background: [0], threshold: ALPHA_THRESHOLD)

    # An image that is transparent throughout trims away to nothing.
    return if width.zero? || height.zero?

    margins = [left, top, image.width - (left + width), image.height - (top + height)]
    return if margins.max < MIN_MARGIN

    image.crop(left, top, width, height).write_to_buffer(".png")
  end

  def attach(buffer)
    attachment.attach(
      io: StringIO.new(buffer),
      filename: png_filename,
      content_type: "image/png",
      metadata: {trimmed: true}
    )
  end

  # The crop is written out as PNG whatever came in, so a name that promised
  # something else must not survive it.
  def png_filename
    "#{File.basename(blob.filename.to_s, ".*")}.png"
  end

  # Nothing to crop is an answer, not a gap. Recording it keeps every later
  # save of the record from downloading the file to find that out again.
  def mark_trimmed
    blob.update!(metadata: blob.metadata.merge(trimmed: true))
    false
  end
end
