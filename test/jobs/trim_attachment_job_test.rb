# frozen_string_literal: true

require "test_helper"
require "vips"

class TrimAttachmentJobTest < ActiveSupport::TestCase
  setup do
    Sidekiq::Worker.clear_all

    @model = create(:model)
  end

  # The crop re-attaches, and the record's own callback asks for the
  # representations of what it attached. Asking for them here as well would
  # build the padded original's too, and then throw them away.
  test "#perform hands the cropped blob on to preprocessing, once" do
    @model.top_view.attach(io: StringIO.new(padded_png), filename: "top.png", content_type: "image/png")
    Sidekiq::Worker.clear_all

    TrimAttachmentJob.new.perform("Model", @model.id, "top_view")

    assert_equal [[@model.reload.top_view.blob.id]], PreprocessRepresentationsJob.jobs.map { |job| job["args"] }
  end

  test "#perform preprocesses what it did not crop" do
    @model.top_view.attach(io: file_fixture("image.jpg").open, filename: "top.jpg")
    Sidekiq::Worker.clear_all

    TrimAttachmentJob.new.perform("Model", @model.id, "top_view")

    assert_equal [[@model.reload.top_view.blob.id]], PreprocessRepresentationsJob.jobs.map { |job| job["args"] }
  end

  test "#perform passes over a record that has gone" do
    assert_nothing_raised do
      TrimAttachmentJob.new.perform("Model", SecureRandom.uuid, "top_view")
    end
  end

  test "#perform passes over an attachment that has gone" do
    assert_nothing_raised do
      TrimAttachmentJob.new.perform("Model", @model.id, "top_view")
    end

    assert_equal 0, PreprocessRepresentationsJob.jobs.size
  end

  private def padded_png
    opaque = Vips::Image.black(100, 40, bands: 3).new_from_image([255, 0, 0]).bandjoin(255).cast(:uchar)

    Vips::Image.black(200, 150, bands: 4).cast(:uchar).insert(opaque, 50, 55).write_to_buffer(".png")
  end
end
