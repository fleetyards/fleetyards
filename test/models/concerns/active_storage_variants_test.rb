# frozen_string_literal: true

require "test_helper"

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

  private def attachable
    {io: file_fixture("test.png").open, filename: "view.png"}
  end

  private def trimmed_blob
    ActiveStorage::Blob.create_and_upload!(**attachable, metadata: {trimmed: true})
  end
end
