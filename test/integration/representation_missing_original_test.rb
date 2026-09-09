# frozen_string_literal: true

require "test_helper"

# Processing a variant downloads the original, so a blob whose original object
# has gone missing raises `FileNotFoundError` out of the `set_representation`
# before_action. Reprocessing cannot repair that -- it downloads the same
# missing object -- so the request has to end as a 404 rather than as a retry.
class RepresentationMissingOriginalTest < ActionDispatch::IntegrationTest
  setup do
    @blob = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("test.png").open,
      filename: "view.png"
    )
    @variant = @blob.variant(resize_to_limit: [100, 100])
  end

  test "a representation whose original is gone is not found" do
    ActiveStorage::Blob.service.delete(@blob.key)

    get representation_path

    assert_response :not_found
  end

  # The same method still repairs the case it was written for, so replacing the
  # handler must not take that with it.
  test "a representation whose own object is gone is rebuilt and served" do
    @variant.processed
    ActiveStorage::Blob.service.delete(@blob.reload.variant_records.sole.image.key)

    get representation_path

    assert_response :redirect
  end

  private def representation_path
    rails_blob_representation_path(
      signed_blob_id: @blob.signed_id,
      variation_key: @variant.variation.key,
      filename: @blob.filename
    )
  end
end
