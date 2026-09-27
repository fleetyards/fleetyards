# frozen_string_literal: true

require "test_helper"

class FrontendTradeRoutesRouteTest < ActionDispatch::IntegrationTest
  test "the path the old page lived under redirects to the tool" do
    get "/trade-routes"

    assert_response :moved_permanently
    assert_redirected_to "/tools/trade-routes/"
  end

  test "the old path with a trailing slash redirects too" do
    get "/trade-routes/"

    assert_redirected_to "/tools/trade-routes/"
  end
end
