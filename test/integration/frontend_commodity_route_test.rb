# frozen_string_literal: true

require "test_helper"

# The server answers this path so a shared link carries the commodity's own
# title, description and icon; without it the card renders the generic site
# blurb.
#
# Recognition rather than a request: rendering the frontend needs Vite assets,
# which CI does not build for the Ruby suite.
class FrontendCommodityRouteTest < ActionDispatch::IntegrationTest
  test "GET catalogue/commodities/:slug reaches the action that sets the meta tags" do
    recognized = Rails.application.routes.recognize_path("/catalogue/commodities/agricium")

    assert_equal "frontend/base", recognized[:controller]
    assert_equal "commodity", recognized[:action]
    assert_equal "agricium", recognized[:slug]
  end

  # The list, which the client router owns -- it must not be swallowed by the
  # detail route.
  test "GET catalogue/commodities without a slug is not the detail action" do
    recognized = Rails.application.routes.recognize_path("/catalogue/commodities")

    assert_not_equal "commodity", recognized[:action]
  end

  # There has never been a public `/commodities` page, so unlike components
  # there is no legacy path to redirect from -- it falls through to the client
  # router's own not-found rather than to a redirect nobody can have bookmarked.
  test "the bare commodities path is left to the client router" do
    recognized = Rails.application.routes.recognize_path("/commodities/agricium")

    assert_equal "frontend/base", recognized[:controller]
    assert_equal "index", recognized[:action]
  end
end
