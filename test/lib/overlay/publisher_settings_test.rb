# frozen_string_literal: true

require "test_helper"

module Overlay
  class PublisherSettingsTest < ActiveSupport::TestCase
    HETZNER = {
      "service" => "S3", "endpoint" => "https://fsn1.example", "access_key_id" => "h-key",
      "secret_access_key" => "h-secret", "bucket" => "uploads", "region" => "unused", "public" => true
    }.freeze
    BUNNY = {
      "service" => "S3", "endpoint" => "https://de-s3.example", "access_key_id" => "zone",
      "secret_access_key" => "b-secret", "bucket" => "zone", "region" => "de", "public" => true
    }.freeze

    private def service_configurations(configs)
      ActiveStorage::Blob.services
      Rails.configuration.active_storage.stubs(:service_configurations).returns(configs)
    end

    test ".settings follows a plain cloud service" do
      service_configurations("cloud" => HETZNER)

      assert_equal [
        {endpoint: "https://fsn1.example", access_key_id: "h-key", secret_access_key: "h-secret", bucket: "uploads", region: "unused"}
      ], Publisher.settings
    end

    test ".settings lists a mirror's primary first, then its mirrors" do
      service_configurations(
        "hetzner" => HETZNER, "bunny" => BUNNY,
        "cloud" => {"service" => "Mirror", "primary" => "bunny", "mirrors" => ["hetzner"]}
      )

      assert_equal %w[zone uploads], Publisher.settings.pluck(:bucket)
      assert_equal %w[de unused], Publisher.settings.pluck(:region)
    end

    test ".configured? needs every value of every store" do
      assert Publisher.configured?([HETZNER.symbolize_keys, BUNNY.symbolize_keys])
      refute Publisher.configured?([HETZNER.symbolize_keys, BUNNY.symbolize_keys.merge(endpoint: nil)])
      refute Publisher.configured?([])
    end

    test ".configured? is false for the unconfigured cloud service of a test run" do
      refute Publisher.configured?
    end
  end
end
