# frozen_string_literal: true

require "test_helper"

class Short::FleetShipsTest < ActionDispatch::IntegrationTest
  setup do
    host! Rails.configuration.app.short_domain
  end

  test "redirects a fleet's FID to its ships page" do
    fleet = create(:fleet, fid: "SHIPS1")

    get "/f/ships1/ships"

    assert_response :found
    assert_match(%r{/fleets/#{fleet.slug}/ships/\z}, response.location)
  end

  test "redirects an unknown FID to the not found page" do
    get "/f/UNKNOWN/ships"

    assert_response :found
    assert_match(%r{/404\z}, response.location)
  end

  test "redirects a discarded fleet's FID to the not found page" do
    fleet = create(:fleet, fid: "GONE1")
    fleet.update_column(:discarded_at, Time.current)

    get "/f/GONE1/ships"

    assert_response :found
    assert_match(%r{/404\z}, response.location)
  end

  test "carries the query, so a link can open the fleetchart" do
    fleet = create(:fleet, fid: "CHART1")

    get "/f/CHART1/ships?fleetchart=true"

    assert_response :found
    assert_match(%r{/fleets/#{fleet.slug}/ships/\?fleetchart=true\z}, response.location)
  end
end
