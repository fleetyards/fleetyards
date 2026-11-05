# frozen_string_literal: true

require "test_helper"

class FrontendFactionRouteTest < ActionDispatch::IntegrationTest
  test "GET catalogue/factions/:slug reaches the action that sets the meta tags" do
    recognized = Rails.application.routes.recognize_path("/catalogue/factions/redwindlinehaul")

    assert_equal "frontend/base", recognized[:controller]
    assert_equal "faction", recognized[:action]
    assert_equal "redwindlinehaul", recognized[:slug]
  end
end
