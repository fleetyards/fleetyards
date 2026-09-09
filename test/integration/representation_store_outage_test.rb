# frozen_string_literal: true

require "test_helper"
require "aws-sdk-s3"

# `show` probes the store for the variant's object so it can rebuild a variant
# record whose object has gone missing. That probe is a repair mechanism, not a
# gate: when the store cannot answer, redirecting is strictly better than
# failing, because signing the URL needs no round trip of its own.
class RepresentationStoreOutageTest < ActionDispatch::IntegrationTest
  setup do
    @blob = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("test.png").open,
      filename: "view.png"
    )
    @variant = @blob.variant(resize_to_limit: [100, 100])
  end

  test "a representation is still redirected when the store cannot answer the probe" do
    ActiveStorage::Blob.service.stubs(:exist?)
      .raises(Aws::S3::Errors::Http503Error.new(nil, "Service Unavailable"))

    get representation_path

    assert_response :redirect
  end

  test "a networking failure against the store is treated the same way" do
    ActiveStorage::Blob.service.stubs(:exist?)
      .raises(Seahorse::Client::NetworkingError.new(Net::ReadTimeout.new))

    get representation_path

    assert_response :redirect
  end

  # The rescue is there for a store that cannot answer, not as a blanket guard
  # over the probe.
  test "an error the store did not raise is left alone" do
    ActiveStorage::Blob.service.stubs(:exist?)
      .raises(RuntimeError, "something we actually broke")

    assert_raises(RuntimeError) { get representation_path }
  end

  private def representation_path
    rails_blob_representation_path(
      signed_blob_id: @blob.signed_id,
      variation_key: @variant.variation.key,
      filename: @blob.filename
    )
  end
end
