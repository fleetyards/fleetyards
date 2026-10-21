# frozen_string_literal: true

require "test_helper"
require "aws-sdk-s3"

module ScData
  class LoadingScreensImportJobTest < ActiveJob::TestCase
    SETTINGS = {
      endpoint: "https://example.invalid",
      access_key_id: "key",
      secret_access_key: "secret",
      bucket: "fltyrd-sc"
    }.freeze

    VERSION = "1.0.0-live.1"
    PNG = Rails.root.join("test/fixtures/files/test.png").binread

    setup do
      Sidekiq::Worker.clear_all

      @objects = {}
      @client = Aws::S3::Client.new(stub_responses: true)
      @client.stub_responses(:list_objects_v2, ->(context) {
        prefix = context.params[:prefix]
        contents = @objects
          .select { |key, _| key.start_with?(prefix) && !key.delete_prefix(prefix).include?("/") }
          .map { |key, (_, etag)| {key:, etag: %("#{etag}"), size: PNG.bytesize} }

        {contents:, common_prefixes: [{prefix: "#{prefix}Data/"}], is_truncated: false}
      })
      @client.stub_responses(:get_object, ->(context) {
        body, = @objects[context.params[:key]]
        body ? {body:} : "NoSuchKey"
      })

      store = ::ScData::RawStore.new(VERSION, client: @client, settings: SETTINGS)
      ::ScData::RawStore.stubs(:configured?).returns(true)
      ::ScData::RawStore.stubs(:new).with(VERSION).returns(store)

      ::ScData::Source.stubs(:configured).returns([::ScData::Source.new(environment: "live", version: VERSION)])
    end

    private def publish(name, etag: "etag-#{name}-2", version: VERSION)
      @objects["#{version}/#{name}"] = [PNG, etag]
    end

    private def fetched
      @client.api_requests
        .select { |request| request[:operation_name] == :get_object }
        .map { |request| request[:params][:key] }
    end

    private def perform
      ::ScData::LoadingScreensImportJob.new.perform
    end

    test "attaches every loading screen of a build" do
      publish("loadingscreen.png")
      publish("loadingscreen_b.png")
      @objects["#{VERSION}/Data/Game2.dcb"] = ["x", "other"]

      perform

      screens = LoadingScreen.where(version: VERSION).sort_by(&:name)

      assert_equal %w[loadingscreen.png loadingscreen_b.png], screens.map(&:name)
      assert screens.all? { |screen| screen.image.attached? }
      assert_equal ["live"], screens.map(&:environment).uniq
      assert_equal "etag-loadingscreen.png-2", screens.first.etag
    end

    test "does not fetch a screen it already has" do
      publish("loadingscreen.png")
      perform

      @client.api_requests.clear
      perform

      assert_empty fetched
    end

    test "replaces a screen whose etag changed" do
      publish("loadingscreen.png")
      perform
      blob = LoadingScreen.find_by!(name: "loadingscreen.png").image.blob

      publish("loadingscreen.png", etag: "changed")
      perform

      screen = LoadingScreen.find_by!(name: "loadingscreen.png")

      assert_equal "changed", screen.etag
      assert_not_equal blob.id, screen.image.blob.id
    end

    test "removes the screens of a build nothing knows about any more" do
      gone = create(:loading_screen, :with_image, version: "0.9.0-live.0")

      perform

      assert_not LoadingScreen.exists?(gone.id)
    end

    test "does nothing without a configured bucket" do
      ::ScData::RawStore.stubs(:configured?).returns(false)
      publish("loadingscreen.png")

      perform

      assert_empty @client.api_requests
      assert_equal 0, LoadingScreen.count
    end
  end
end
