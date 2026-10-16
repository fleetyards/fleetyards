# frozen_string_literal: true

require "test_helper"
require "vips"

class TrimAttachmentJobTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

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

  test "#perform takes the view off the pending list" do
    @model.top_view.attach(io: StringIO.new(padded_png), filename: "top.png", content_type: "image/png")
    @model.update_columns(pending_trims: pending("top_view", "port_view"))

    TrimAttachmentJob.new.perform("Model", @model.id, "top_view")

    assert_equal %w[port_view], @model.reload.pending_trims.keys
  end

  test "#perform takes an attachment that has gone off the pending list" do
    @model.update_columns(pending_trims: pending("top_view"))

    TrimAttachmentJob.new.perform("Model", @model.id, "top_view")

    assert_empty @model.reload.pending_trims
  end

  test "#perform tells admins with access to models what is still pending" do
    admin_user = create(:admin_user, resource_access: [:models])
    create(:admin_user, resource_access: [:users])
    @model.update_columns(pending_trims: pending("top_view", "port_view"))

    assert_broadcasts(AdminModelMediaChannel.broadcasting_for(admin_user), 1) do
      TrimAttachmentJob.new.perform("Model", @model.id, "top_view")
    end

    assert_equal({"modelId" => @model.id, "mediaProcessing" => ["portView"]},
      broadcasts(AdminModelMediaChannel.broadcasting_for(admin_user)).map { |message| JSON.parse(message) }.first)
  end

  test "a crop that ran out of retries leaves the pending list" do
    @model.update_columns(pending_trims: pending("top_view"))

    TrimAttachmentJob.sidekiq_retries_exhausted_block.call(
      {"args" => ["Model", @model.id, "top_view"]}, StandardError.new
    )

    assert_empty @model.reload.pending_trims
  end

  test "#perform crops a view a job queued before the rename calls a side view" do
    @model.landed_port_view.attach(io: StringIO.new(padded_png), filename: "port.png", content_type: "image/png")
    @model.update_columns(pending_trims: pending("landed_port_view"))
    padded = @model.landed_port_view.blob

    TrimAttachmentJob.new.perform("Model", @model.id, "landed_side_view")

    assert_not_equal padded, @model.reload.landed_port_view.blob
    assert_empty @model.pending_trims
  end

  test "a side view crop that ran out of retries leaves the pending list" do
    @model.update_columns(pending_trims: pending("port_view"))

    TrimAttachmentJob.sidekiq_retries_exhausted_block.call(
      {"args" => ["Model", @model.id, "side_view"]}, StandardError.new
    )

    assert_empty @model.reload.pending_trims
  end

  private def pending(*names)
    names.index_with { Time.current.iso8601(6) }
  end

  private def padded_png
    opaque = Vips::Image.black(100, 40, bands: 3).new_from_image([255, 0, 0]).bandjoin(255).cast(:uchar)

    Vips::Image.black(200, 150, bands: 4).cast(:uchar).insert(opaque, 50, 55).write_to_buffer(".png")
  end
end
