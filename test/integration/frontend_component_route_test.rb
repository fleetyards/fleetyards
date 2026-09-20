# frozen_string_literal: true

require "test_helper"

# The server answers this path so a shared link carries the component's own
# title and description; without it the card renders the generic site blurb.
#
# Recognition rather than a request: rendering the frontend needs Vite assets,
# which CI does not build for the Ruby suite.
class FrontendComponentRouteTest < ActionDispatch::IntegrationTest
  test "GET catalogue/components/:slug reaches the action that sets the meta tags" do
    recognized = Rails.application.routes.recognize_path("/catalogue/components/bulldog-repeater")

    assert_equal "frontend/base", recognized[:controller]
    assert_equal "component", recognized[:action]
    assert_equal "bulldog-repeater", recognized[:slug]
  end

  # The list, which the client router owns -- it must not be swallowed by the
  # detail route.
  test "GET catalogue/components without a slug is not the detail action" do
    recognized = Rails.application.routes.recognize_path("/catalogue/components")

    assert_not_equal "component", recognized[:action]
  end

  # The history tab is a sibling of the overview, so its path sits one segment
  # deeper. `:slug` does not match a slash, so the meta-tag route leaves it to
  # the client router -- asserted because a greedier segment there would answer
  # the tab with the overview's meta tags and never reach the page.
  test "GET catalogue/components/:slug/history is left to the client router" do
    recognized = Rails.application.routes.recognize_path("/catalogue/components/bulldog-repeater/history")

    assert_equal "frontend/base", recognized[:controller]
    assert_equal "index", recognized[:action]
  end

  # The pages were live under the old path before the section existed, and
  # every hardpoint on every ship linked to it.
  test "the path the detail page shipped under still resolves" do
    get "/components/bulldog-repeater"

    assert_redirected_to "/catalogue/components/bulldog-repeater"
  end
end
