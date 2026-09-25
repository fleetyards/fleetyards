# frozen_string_literal: true

require "test_helper"

# Recognition rather than a request: rendering the frontend needs Vite assets,
# which CI does not build for the Ruby suite.
class FrontendEquipmentRouteTest < ActionDispatch::IntegrationTest
  test "GET catalogue/equipment/:slug reaches the action that sets the meta tags" do
    recognized = Rails.application.routes.recognize_path("/catalogue/equipment/p4-ar-rifle")

    assert_equal "frontend/base", recognized[:controller]
    assert_equal "equipment", recognized[:action]
    assert_equal "p4-ar-rifle", recognized[:slug]
  end

  # The list, which the client router owns.
  test "GET catalogue/equipment without a slug is not the detail action" do
    recognized = Rails.application.routes.recognize_path("/catalogue/equipment")

    assert_not_equal "equipment", recognized[:action]
  end
end
