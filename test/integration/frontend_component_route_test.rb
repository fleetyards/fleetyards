# frozen_string_literal: true

require "test_helper"

# The server answers this path so a shared link carries the component's own
# title and description; without it the card renders the generic site blurb.
#
# Recognition rather than a request: rendering the frontend needs Vite assets,
# which CI does not build for the Ruby suite.
class FrontendComponentRouteTest < ActionDispatch::IntegrationTest
  test "GET components/:slug reaches the action that sets the meta tags" do
    recognized = Rails.application.routes.recognize_path("/components/bulldog-repeater")

    assert_equal "frontend/base", recognized[:controller]
    assert_equal "component", recognized[:action]
    assert_equal "bulldog-repeater", recognized[:slug]
  end

  # `/components` itself is the catalogue list, which the client router owns --
  # it must not be swallowed by the detail route.
  test "GET components without a slug is not the detail action" do
    recognized = Rails.application.routes.recognize_path("/components")

    assert_not_equal "component", recognized[:action]
  end
end
