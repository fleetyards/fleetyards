# frozen_string_literal: true

require "test_helper"
require "vips"

class ActiveStorageVariantsTest < ActiveSupport::TestCase
  setup do
    Sidekiq::Worker.clear_all

    @model = create(:model)
  end

  test "a declared attachment goes to the trimmer first" do
    @model.top_view.attach(attachable)

    assert_equal 1, TrimAttachmentJob.jobs.size
    assert_equal ["Model", @model.id, "top_view"], TrimAttachmentJob.jobs.first["args"]
  end

  # Representations of the padded original would only be thrown away by the
  # crop that follows.
  test "a declared attachment builds no representations until it is trimmed" do
    @model.top_view.attach(attachable)

    assert_equal 0, PreprocessRepresentationsJob.jobs.size
  end

  test "an attachment nobody declared is preprocessed as before" do
    @model.store_image.attach(attachable)

    assert_equal 0, TrimAttachmentJob.jobs.size
    assert_equal 1, PreprocessRepresentationsJob.jobs.size
  end

  test "a model that declares nothing trims nothing" do
    create(:manufacturer).logo.attach(attachable)

    assert_equal 0, TrimAttachmentJob.jobs.size
    assert_equal 1, PreprocessRepresentationsJob.jobs.size
  end

  # What the trimmer re-attaches comes back through here, and this time it is
  # the representations that are wanted.
  test "an attachment the trimmer has been over is preprocessed" do
    @model.top_view.attach(trimmed_blob)

    assert_equal 0, TrimAttachmentJob.jobs.size
    assert_equal 1, PreprocessRepresentationsJob.jobs.size
  end

  # A record carrying twenty views would otherwise queue every one of them again
  # for every crop the trimmer makes.
  test "only what a save attached is preprocessed" do
    @model.store_image.attach(attachable)
    Sidekiq::Worker.clear_all

    @model.rsi_store_image.attach(attachable)

    assert_equal 1, PreprocessRepresentationsJob.jobs.size
    assert_equal [@model.reload.rsi_store_image.blob.id], PreprocessRepresentationsJob.jobs.first["args"]
  end

  # An upload that came through the direct-upload endpoint is already in
  # storage, so the crop can happen before the response rather than behind it --
  # otherwise the page that follows the save draws the padded original and only
  # a reload replaces it.
  class InlineTrimTest < ActiveStorageVariantsTest
    test "a signed id is trimmed in the request" do
      @model.top_view.attach(padded_blob.signed_id)

      assert_equal 0, TrimAttachmentJob.jobs.size
      assert @model.reload.top_view.blob.metadata["trimmed"]

      cropped = Vips::Image.new_from_buffer(@model.top_view.blob.download, "")
      assert_equal [100, 40], [cropped.width, cropped.height]
    end

    test "a blob that needed no crop is preprocessed without the job" do
      @model.top_view.attach(ActiveStorage::Blob.create_and_upload!(
        io: file_fixture("image.jpg").open, filename: "top.jpg"
      ))

      assert_equal 0, TrimAttachmentJob.jobs.size
      assert_equal 1, PreprocessRepresentationsJob.jobs.size
    end

    # The bytes of a file posted with the form are uploaded in an `after_commit`
    # of ActiveStorage's own, which may not have run yet.
    test "a file posted with the form still goes through the job" do
      @model.top_view.attach(io: StringIO.new(padded_png), filename: "top.png")

      assert_equal 1, TrimAttachmentJob.jobs.size
    end

    # A purge is a change like any other, and the record asks every change what
    # it is carrying before anything has decided which attachments are still
    # there. `DeleteOne` carries no attachable at all.
    test "purging an attachment raises nothing" do
      @model.top_view.attach(padded_blob.signed_id)

      assert_nothing_raised { @model.top_view.purge }

      refute_predicate @model.reload.top_view, :attached?
    end

    private def padded_blob
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(padded_png), filename: "top.png", content_type: "image/png"
      )
    end

    private def padded_png
      opaque = Vips::Image.black(100, 40, bands: 3).new_from_image([255, 0, 0]).bandjoin(255).cast(:uchar)

      Vips::Image.black(200, 150, bands: 4).cast(:uchar).insert(opaque, 50, 55).write_to_buffer(".png")
    end
  end

  private def attachable
    {io: file_fixture("test.png").open, filename: "view.png"}
  end

  private def trimmed_blob
    ActiveStorage::Blob.create_and_upload!(**attachable, metadata: {trimmed: true})
  end
end
