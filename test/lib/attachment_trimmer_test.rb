# frozen_string_literal: true

require "test_helper"
require "vips"

class AttachmentTrimmerTest < ActiveSupport::TestCase
  setup do
    Sidekiq::Worker.clear_all

    @model = create(:model)
  end

  test "#call crops the transparent padding away" do
    attach(padded_png)

    assert AttachmentTrimmer.new(view).call

    assert_equal [100, 40], dimensions_of(view)
  end

  # The fleetchart sizes a ship from these two numbers, so a crop nothing reads
  # afterwards would be worse than none at all.
  test "#call leaves the blob to report the cropped size" do
    attach(padded_png)

    AttachmentTrimmer.new(view).call
    view.blob.analyze

    assert_equal 100, view.blob.metadata[:width]
    assert_equal 40, view.blob.metadata[:height]
  end

  test "#call replaces the blob rather than editing the one in place" do
    attach(padded_png)
    original = view.blob

    AttachmentTrimmer.new(view).call

    assert_not_equal original.id, reloaded_view.blob.id
    assert_not_equal original.key, reloaded_view.blob.key
  end

  test "#call names the crop for what it wrote" do
    attach(padded_png, filename: "angled.jpg")

    AttachmentTrimmer.new(view).call

    assert_equal "angled.png", view.blob.filename.to_s
    assert_equal "image/png", view.blob.content_type
  end

  test "#call leaves an image that is already tight against its subject" do
    attach(padded_png(canvas: [100, 40], at: [0, 0]))
    original = view.blob

    assert_not AttachmentTrimmer.new(view).call

    assert_equal original.id, reloaded_view.blob.id
  end

  # What the renders actually carry: a pixel of near-transparency where the hull
  # meets the canvas. Replacing the blob over that would be churn.
  test "#call leaves an antialiased edge where it is" do
    attach(padded_png(canvas: [102, 42], at: [1, 1]))
    original = view.blob

    assert_not AttachmentTrimmer.new(view).call

    assert_equal original.id, reloaded_view.blob.id
  end

  # Without an alpha channel there is no transparency to go by, and guessing
  # from the corner pixel would eat into a subject that reaches the frame.
  test "#call leaves an image without an alpha channel" do
    view.attach(io: file_fixture("image.jpg").open, filename: "image.jpg")
    original = view.blob

    assert_not AttachmentTrimmer.new(view).call

    assert_equal original.id, reloaded_view.blob.id
  end

  test "#call leaves a vector alone" do
    view.attach(io: file_fixture("vector.svg").open, filename: "vector.svg")
    original = view.blob

    assert_not AttachmentTrimmer.new(view).call

    assert_equal original.id, reloaded_view.blob.id
  end

  # An image that is transparent throughout trims away to nothing, which is not
  # a crop anyone asked for.
  test "#call leaves an image with nothing opaque in it" do
    attach(padded_png(block: nil))
    original = view.blob

    assert_not AttachmentTrimmer.new(view).call

    assert_predicate reloaded_view, :attached?
    assert_equal original.id, reloaded_view.blob.id
  end

  test "#call does not crop what it has already cropped" do
    attach(padded_png)

    AttachmentTrimmer.new(view).call
    cropped = reloaded_view.blob

    assert_not AttachmentTrimmer.new(reloaded_view).call

    assert_equal cropped.id, reloaded_view.blob.id
    assert_equal [100, 40], dimensions_of(reloaded_view)
  end

  # Recording the decision is what keeps every later save of the record from
  # downloading the file to reach it again.
  test "#call records that it looked at an image it left alone" do
    attach(padded_png(canvas: [100, 40], at: [0, 0]))

    AttachmentTrimmer.new(view).call

    assert view.blob.reload.metadata[:trimmed]
  end

  private def view
    @model.top_view
  end

  private def reloaded_view
    @model.reload.top_view
  end

  private def attach(buffer, filename: "angled.png")
    view.attach(io: StringIO.new(buffer), filename:, content_type: "image/png")
  end

  private def dimensions_of(attachment)
    image = Vips::Image.new_from_buffer(attachment.download, "")

    [image.width, image.height]
  end

  # Transparency with a single opaque block in it, so the crop has one right
  # answer. `block: nil` leaves the canvas empty.
  private def padded_png(canvas: [200, 150], block: [100, 40], at: [50, 55])
    image = Vips::Image.black(*canvas, bands: 4).cast(:uchar)

    if block
      opaque = Vips::Image.black(*block, bands: 3)
        .new_from_image([255, 0, 0])
        .bandjoin(255)
        .cast(:uchar)

      image = image.insert(opaque, *at)
    end

    image.write_to_buffer(".png")
  end
end
