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

  # Processing a variant for the first time reads and writes the store before
  # `show` runs, so the probe's rescue never sees these.
  test "a variant that cannot be stored answers 503 with a retry hint" do
    ActiveStorage::Blob.service.stubs(:upload)
      .raises(store_error("Http503Error", 503))

    get representation_path

    assert_response :service_unavailable
    assert_equal "30", response.headers["Retry-After"]
  end

  test "a networking failure while storing a variant answers the same way" do
    ActiveStorage::Blob.service.stubs(:upload)
      .raises(Seahorse::Client::NetworkingError.new(Net::ReadTimeout.new))

    get representation_path

    assert_response :service_unavailable
  end

  test "a refused credential is not presented as an outage" do
    ActiveStorage::Blob.service.stubs(:upload).raises(store_error("AccessDenied", 403))

    assert_raises(Aws::S3::Errors::AccessDenied) { get representation_path }
  end

  {"Http429Error" => 429, "Http507Error" => 507, "BadGateway" => 502, "SlowDown" => 503}.each do |code, status|
    test "#{code} from the store answers 503" do
      ActiveStorage::Blob.service.stubs(:upload).raises(store_error(code, status))

      get representation_path

      assert_response :service_unavailable
    end
  end

  test "a request timeout from the store answers 503 despite its 400" do
    ActiveStorage::Blob.service.stubs(:upload).raises(store_error("RequestTimeout", 400))

    get representation_path

    assert_response :service_unavailable
  end

  test "an outage is counted, as it opens no incident" do
    ActiveStorage::Blob.service.stubs(:upload)
      .raises(Seahorse::Client::NetworkingError.new(Net::ReadTimeout.new))
    Appsignal.expects(:increment_counter)
      .with("storage_unavailable", 1, error: "Seahorse::Client::NetworkingError").once

    get representation_path
  end

  test "a refused credential on the probe still redirects, and is reported" do
    error = store_error("AccessDenied", 403)
    ActiveStorage::Blob.service.stubs(:exist?).raises(error)
    Appsignal.expects(:report_error).with(error).once

    get representation_path

    assert_response :redirect
    assert_no_match(/max-age/, response.headers["Cache-Control"].to_s)
  end

  test "an outage on the probe is not reported as an error" do
    ActiveStorage::Blob.service.stubs(:exist?).raises(store_error("SlowDown", 503))
    Appsignal.expects(:report_error).never

    get representation_path

    assert_response :redirect
  end

  test "a redirect the store could not vouch for is not cached" do
    ActiveStorage::Blob.service.stubs(:exist?)
      .raises(Aws::S3::Errors::Http503Error.new(nil, "Service Unavailable"))

    get representation_path

    assert_response :redirect
    assert_no_match(/max-age/, response.headers["Cache-Control"].to_s)
  end

  test "a redirect the store confirmed stays cacheable" do
    get representation_path

    assert_response :redirect
    assert_match(/max-age/, response.headers["Cache-Control"].to_s)
  end

  # The rescue is there for a store that cannot answer, not as a blanket guard
  # over the probe.
  test "an error the store did not raise is left alone" do
    ActiveStorage::Blob.service.stubs(:exist?)
      .raises(RuntimeError, "something we actually broke")

    assert_raises(RuntimeError) { get representation_path }
  end

  private def store_error(code, status)
    context = stub(http_response: stub(status_code: status))

    Aws::S3::Errors.const_get(code).new(context, code)
  end

  private def representation_path
    rails_blob_representation_path(
      signed_blob_id: @blob.signed_id,
      variation_key: @variant.variation.key,
      filename: @blob.filename
    )
  end
end
