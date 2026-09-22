# frozen_string_literal: true

require "test_helper"

# An emblem carries its own cut-out or it reads as a sticker over the layout.
# The check asks vips for the alpha channel, because the content type cannot
# answer it -- a PNG may be flattened onto white and still be a PNG.
class TransparentImageValidatorTest < ActiveSupport::TestCase
  setup do
    @fleet = create(:fleet)
  end

  def upload(name, type)
    Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files", name), type)
  end

  test "a transparent png is accepted as an icon and as a logo" do
    squadron = build(:fleet_squadron, fleet: @fleet)
    squadron.icon.attach(upload("test.png", "image/png"))
    squadron.logo.attach(upload("test.png", "image/png"))

    assert_predicate squadron, :valid?
  end

  test "an opaque jpeg is refused as an icon" do
    squadron = build(:fleet_squadron, fleet: @fleet)
    squadron.icon.attach(upload("image.jpg", "image/jpeg"))

    assert_not squadron.valid?
    assert_includes squadron.errors.attribute_names, :icon
  end

  test "an opaque jpeg is refused as a logo" do
    squadron = build(:fleet_squadron, fleet: @fleet)
    squadron.logo.attach(upload("image.jpg", "image/jpeg"))

    assert_not squadron.valid?
    assert_includes squadron.errors.attribute_names, :logo
  end

  # The banner sits behind a heading and has nothing to cut out of, so it is the
  # one picture here that is allowed to be a photograph.
  test "an opaque jpeg is accepted as a header" do
    squadron = build(:fleet_squadron, fleet: @fleet)
    squadron.header.attach(upload("image.jpg", "image/jpeg"))

    assert_predicate squadron, :valid?
  end

  # Only what this save attaches: a squadron that picked up an opaque mark
  # before the rule existed has to stay editable.
  test "an attachment nobody touched is not re-checked" do
    squadron = create(:fleet_squadron, fleet: @fleet)
    squadron.icon.attach(upload("image.jpg", "image/jpeg"))
    squadron.save(validate: false)

    squadron.reload.name = "Renamed Wing"

    assert_predicate squadron, :valid?
  end

  test "the message names what is wrong rather than the rule" do
    squadron = build(:fleet_squadron, fleet: @fleet)
    squadron.icon.attach(upload("image.jpg", "image/jpeg"))
    squadron.validate

    assert_match(/transparent/, squadron.errors[:icon].first)
  end
end
