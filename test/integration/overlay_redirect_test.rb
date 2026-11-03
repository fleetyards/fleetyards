# frozen_string_literal: true

require "test_helper"

class OverlayRedirectTest < ActionDispatch::IntegrationTest
  setup do
    host! Rails.configuration.app.domain
    Rails.configuration.app.stubs(:storage_cdn_endpoint).returns("https://storage.test")
  end

  test "the manifest and items files redirect to the storage CDN" do
    get "/overlay/live/manifest.json"
    assert_redirected_to "https://storage.test/overlay/live/manifest.json"

    get "/overlay/ptu/items.0123456789abcdef.json.gz"
    assert_redirected_to "https://storage.test/overlay/ptu/items.0123456789abcdef.json.gz"
  end

  test "nothing else under the prefix reaches the bucket" do
    get "/overlay/live/secrets.json"
    assert_not response.location.to_s.start_with?("https://storage.test"), response.location
  end

  test "only the frontend host answers" do
    host! "api.example.com"
    get "/overlay/live/manifest.json"

    assert_not response.location.to_s.start_with?("https://storage.test"), response.location
  end
end
