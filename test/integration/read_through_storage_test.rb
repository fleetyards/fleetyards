# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"
require "active_storage/service/read_through_disk_service"

class ReadThroughStorageTest < ActionDispatch::IntegrationTest
  KEY = "abcd1234"

  setup do
    @root = Dir.mktmpdir
    @service = ActiveStorage::Service::ReadThroughDiskService.new(root: @root, origin: "https://storage.example.test")
    @service.name = :read_through
    ActiveStorage::Blob.services.send(:services)[:read_through] = @service
  end

  teardown do
    ActiveStorage::Blob.services.send(:services).delete(:read_through)
    FileUtils.rm_rf(@root)
  end

  test "the disk controller serves a file it has to fetch first" do
    stub_request(:get, "https://storage.example.test/#{KEY}").to_return(body: "remote")

    get disk_path

    assert_response :success
    assert_equal "remote", response.body
  end

  test "the disk controller answers 404 for a file the origin does not have" do
    stub_request(:get, "https://storage.example.test/#{KEY}").to_return(status: 404)

    get disk_path

    assert_response :not_found
  end

  private

  def disk_path
    token = ActiveStorage.verifier.generate(
      {key: KEY, disposition: "inline", content_type: "text/plain", service_name: "read_through"},
      purpose: :blob_key
    )

    Rails.application.routes.url_helpers.rails_disk_service_path(token, filename: "file.txt")
  end
end
