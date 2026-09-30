# frozen_string_literal: true

require "test_helper"

class ServiceWorkerCacheControlTest < ActiveSupport::TestCase
  def call(path)
    app = ->(_env) { [200, {"cache-control" => "public, max-age=31536000, immutable"}, []] }

    Middleware::ServiceWorkerCacheControl.new(app).call("PATH_INFO" => path)
  end

  test "the service worker is revalidated on every load" do
    _status, headers, _body = call("/sw.js")

    assert_equal "no-cache", headers["cache-control"]
  end

  test "so is its source map" do
    _status, headers, _body = call("/sw.js.map")

    assert_equal "no-cache", headers["cache-control"]
  end

  test "fingerprinted assets keep their long cache" do
    _status, headers, _body = call("/vite/assets/application-abc123.js")

    assert_equal "public, max-age=31536000, immutable", headers["cache-control"]
  end

  test "sits in the stack" do
    assert_includes Rails.application.middleware.map(&:klass), Middleware::ServiceWorkerCacheControl
  end
end
