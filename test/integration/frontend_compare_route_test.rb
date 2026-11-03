# frozen_string_literal: true

require "test_helper"

# Recognition rather than a request: rendering the frontend needs Vite assets,
# which CI does not build for the Ruby suite.
class FrontendCompareRouteTest < ActionDispatch::IntegrationTest
  test "GET compare/components reaches the action that sets the meta tags" do
    recognized = Rails.application.routes.recognize_path("/compare/components")

    assert_equal "frontend/base", recognized[:controller]
    assert_equal "compare_components", recognized[:action]
  end

  test "GET compare/equipment reaches the action that sets the meta tags" do
    recognized = Rails.application.routes.recognize_path("/compare/equipment")

    assert_equal "frontend/base", recognized[:controller]
    assert_equal "compare_equipment", recognized[:action]
  end

  test "GET compare still reaches the ship compare" do
    recognized = Rails.application.routes.recognize_path("/compare")

    assert_equal "compare_models", recognized[:action]
  end
end
