# frozen_string_literal: true

require "test_helper"

# The server answers this path so a shared link carries the place's own title
# and description. Recognition rather than a request: rendering the frontend
# needs Vite assets, which CI does not build for the Ruby suite.
class FrontendLocationRouteTest < ActionDispatch::IntegrationTest
  test "GET locations/:slug reaches the action that sets the meta tags" do
    recognized = Rails.application.routes.recognize_path("/locations/outpost-54-aberdeen")

    assert_equal "frontend/base", recognized[:controller]
    assert_equal "location", recognized[:action]
    assert_equal "outpost-54-aberdeen", recognized[:slug]
  end

  test "GET locations without a slug is not the detail action" do
    recognized = Rails.application.routes.recognize_path("/locations")

    assert_not_equal "location", recognized[:action]
  end
end
