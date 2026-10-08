# frozen_string_literal: true

require "test_helper"

class Short::FleetEventTest < ActionDispatch::IntegrationTest
  setup do
    host! Rails.configuration.app.short_domain
  end

  test "redirects to the event and keeps the occurrence" do
    fleet = create(:fleet, fid: "EVENT1")
    event = create(:fleet_event, fleet:)

    get "/fe/event1/#{event.slug}?occurrence=2026-10-10"

    assert_response :found
    assert_match(%r{/fleets/#{fleet.slug}/events/#{event.slug}/\?occurrence=2026-10-10\z}, response.location)
  end

  test "redirects an unknown event to the not found page" do
    create(:fleet, fid: "EVENT2")

    get "/fe/EVENT2/missing"

    assert_response :found
    assert_match(%r{/404\z}, response.location)
  end
end
