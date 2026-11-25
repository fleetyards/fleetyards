# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"
require "active_storage/service/read_through_disk_service"

class ReadThroughDiskServiceTest < ActiveSupport::TestCase
  ORIGIN = "https://storage.example.test"
  KEY = "abcd1234"
  URL = "#{ORIGIN}/#{KEY}"

  setup do
    @root = Dir.mktmpdir
    @service = build(ORIGIN)
  end

  teardown { FileUtils.rm_rf(@root) }

  test "#download fetches a missing file once" do
    get = stub_request(:get, URL).to_return(body: "remote")

    2.times { assert_equal "remote", @service.download(KEY) }

    assert_requested get, times: 1
    assert_equal [@service.path_for(KEY)], files
  end

  test "#download streams a missing file" do
    stub_request(:get, URL).to_return(body: "remote")

    chunks = []
    @service.download(KEY) { |chunk| chunks << chunk }

    assert_equal "remote", chunks.join
  end

  test "#download_chunk fetches a missing file" do
    stub_request(:get, URL).to_return(body: "remote")

    assert_equal "emo", @service.download_chunk(KEY, 1..3)
  end

  test "#download prefers the local file" do
    @service.upload(KEY, StringIO.new("local"))

    assert_equal "local", @service.download(KEY)
    assert_not_requested :any, /.*/
  end

  test "#download reports a file the origin does not have" do
    stub_request(:get, URL).to_return(status: 404)

    assert_raises(ActiveStorage::FileNotFoundError) { @service.download(KEY) }
    assert_empty files
  end

  test "#download reports a file while the origin is unreachable" do
    stub_request(:get, URL).to_timeout

    assert_raises(ActiveStorage::FileNotFoundError) { @service.download(KEY) }
    assert_empty files
  end

  test "#exist? asks the origin without downloading" do
    stub_request(:head, URL).to_return(status: 200)
    stub_request(:head, "#{ORIGIN}/missing").to_return(status: 404)

    assert @service.exist?(KEY)
    assert_equal false, @service.exist?("missing")
    assert_empty files
  end

  test "writes and deletes stay local" do
    @service.upload(KEY, StringIO.new("local"))
    @service.delete(KEY)
    @service.delete(KEY)
    @service.delete_prefixed("abcd")

    assert_not_requested :any, /.*/
    assert_empty files
  end

  test "only plain keys are requested from the origin" do
    assert_raises(ActiveStorage::FileNotFoundError) { @service.download("overlay/live/manifest.json") }
    assert_raises(ActiveStorage::InvalidKeyError) { @service.download("../secret") }
    assert_not_requested :any, /.*/
  end

  test "without an origin it is a plain disk service" do
    service = build("")

    assert_raises(ActiveStorage::FileNotFoundError) { service.download(KEY) }
    assert_equal false, service.exist?(KEY)
    assert_not_requested :any, /.*/
  end

  private

  def build(origin)
    ActiveStorage::Service::ReadThroughDiskService.new(root: @root, origin: origin).tap { |service| service.name = :local }
  end

  def files
    Dir.glob("#{@root}/**/*", File::FNM_DOTMATCH).select { |path| File.file?(path) }
  end
end
