# frozen_string_literal: true

require "test_helper"

module Overlay
  class PublisherSettingsTest < ActiveSupport::TestCase
    test ".settings reads the upload store through Rails.app.creds, so ENV can point it elsewhere" do
      creds = Rails.app.creds
      creds.stubs(:option).returns(nil)
      creds.stubs(:option).with(:s3_protocol).returns("https")
      creds.stubs(:option).with(:s3_endpoint).returns("de-s3.storage.bunnycdn.com")
      creds.stubs(:option).with(:s3_access_key).returns("zone")
      creds.stubs(:option).with(:s3_secret_key).returns("secret")
      creds.stubs(:option).with(:s3_bucket).returns("zone")
      creds.stubs(:option).with(:s3_region, default: "unused").returns("de")

      assert_equal(
        {endpoint: "https://de-s3.storage.bunnycdn.com", access_key_id: "zone", secret_access_key: "secret", bucket: "zone", region: "de"},
        Publisher.settings
      )
    end

    test ".settings falls back to the placeholder region the Hetzner store has always been given" do
      Rails.app.creds.stubs(:option).returns(nil)
      Rails.app.creds.stubs(:option).with(:s3_region, default: "unused").returns("unused")

      assert_equal "unused", Publisher.settings[:region]
    end

    test ".endpoint is nil unless both halves are present" do
      assert_equal "https://s3.test", Publisher.endpoint("https", "s3.test")
      assert_nil Publisher.endpoint("https", nil)
      assert_nil Publisher.endpoint(nil, "s3.test")
    end
  end
end
