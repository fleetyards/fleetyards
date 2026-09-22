# frozen_string_literal: true

require "test_helper"

# The server answers this path so a shared link carries the mission's own title
# and description; without it the card renders the generic site blurb.
#
# Recognition rather than a request: rendering the frontend needs Vite assets,
# which CI does not build for the Ruby suite.
class FrontendMissionRouteTest < ActionDispatch::IntegrationTest
  test "GET catalogue/missions/:slug reaches the action that sets the meta tags" do
    recognized = Rails.application.routes.recognize_path("/catalogue/missions/foxwellenforcement-ambush-veryeasy")

    assert_equal "frontend/base", recognized[:controller]
    assert_equal "mission", recognized[:action]
    assert_equal "foxwellenforcement-ambush-veryeasy", recognized[:slug]
  end

  # The list, which the client router owns -- it must not be swallowed by the
  # detail route.
  test "GET catalogue/missions without a slug is not the detail action" do
    recognized = Rails.application.routes.recognize_path("/catalogue/missions")

    assert_not_equal "mission", recognized[:action]
  end
end
