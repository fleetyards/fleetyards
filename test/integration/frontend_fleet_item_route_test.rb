# frozen_string_literal: true

require "test_helper"

# The server answers these paths so a shared link carries what `LinkPreview`
# allows it to say; without them the card renders the generic site blurb.
#
# Recognition rather than a request: rendering the frontend needs Vite assets,
# which CI does not build for the Ruby suite.
class FrontendFleetItemRouteTest < ActionDispatch::IntegrationTest
  {
    "/fleets/ember/events/mining-night" => ["frontend/fleets", "event"],
    "/fleets/ember/contracts/ore-run" => ["frontend/fleets", "contract"],
    "/fleets/ember/tours/stanton-loop" => ["frontend/fleets", "tour"],
    "/tools/tours/stanton-loop" => ["frontend/tours", "show"],
    "/tools/tours/join/abc123" => ["frontend/tours", "join"]
  }.each do |path, (controller, action)|
    test "GET #{path} reaches the action that sets the preview" do
      recognized = Rails.application.routes.recognize_path(path)

      assert_equal controller, recognized[:controller]
      assert_equal action, recognized[:action]
    end
  end

  # The pages below a contract are the client router's, not the preview's.
  test "GET a contract's sub-page is not the preview action" do
    recognized = Rails.application.routes.recognize_path("/fleets/ember/contracts/ore-run/edit")

    assert_not_equal "contract", recognized[:action]
  end
end

class FrontendFleetItemPreviewTest < ActionDispatch::IntegrationTest
  setup do
    ViteRuby.instance.stubs(:dev_server_running?).returns(true)

    @fleet = create(:fleet, name: "Ember Guard")
  end

  test "an event's preview names it only when every member sees it" do
    open = create(:fleet_event, :open, fleet: @fleet, title: "Mining night")
    restricted = create(:fleet_event, :open, fleet: @fleet, title: "Secret op", visibility: "officers")

    get "/fleets/#{@fleet.slug}/events/#{open.slug}"
    assert_includes og_title, "Mining night"

    get "/fleets/#{@fleet.slug}/events/#{restricted.slug}"
    assert_includes og_title, "Fleet event in Ember Guard"
    assert_not_includes response.body, "Secret op"
  end

  test "a draft contract's preview does not name it" do
    contract = create(:fleet_contract, fleet: @fleet, title: "Ore run")

    get "/fleets/#{@fleet.slug}/contracts/#{contract.slug}"

    assert_includes og_title, "Contract in Ember Guard"
  end

  test "a tour invite's preview names the tour" do
    tour = create(:tour, title: "Private loop")

    get "/tools/tours/join/#{tour.invite_token}"

    assert_includes og_title, "Join Private loop"
  end

  private def og_title
    assert_response :success

    response.body[/<meta property="og:title" content="([^"]*)"/, 1].to_s
  end
end
