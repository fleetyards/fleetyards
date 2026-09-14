# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsToursIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/tours" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    get("List Fleet Tours") do
      operationId "fleetTours"
      tags "Tours"
      produces "application/json"

      parameter ::Shared::V1::Parameters::PageParameter
      parameter ::Shared::V1::Parameters::SortingParameter

      security [
        {SessionCookie: []},
        {Oauth2: ["user"]},
        {OpenId: ["user"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::ToursList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("tour_payouts")
    Flipper.enable("fleet_tours")

    @admin = create(:user)
    @member = create(:user)
    @outsider = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])

    @tour = create(:tour, fleet: @fleet, created_by: @admin)
  end

  def path_params
    {fleetSlug: @fleet.slug}
  end

  # The point of the fleet-scoped list: a member sees the fleet's tours without
  # having organised or joined any of them.
  test "GET lists the fleet's tours for a member who is on none of them" do
    sign_in @member

    assert_api_response :get, 200, path_params: path_params do
      assert_equal [@tour.id], parsed_body["items"].map { |item| item["id"] }
    end
  end

  # Reading the list is a membership right, not a payout one. A fleet whose
  # roles predate the payout privileges has nobody holding them, and its members
  # would otherwise find the page empty and the nav item gone.
  test "GET lists the fleet's tours for a member with no payout privileges" do
    @fleet.default_member_role.update!(resource_access: [])
    sign_in @member

    assert_api_response :get, 200, path_params: path_params do
      assert_equal [@tour.id], parsed_body["items"].map { |item| item["id"] }
    end
  end

  # The list is what a member reads to find a tour to ask onto, so it says
  # where they already stand on each one.
  test "GET says whether the viewer is on each tour" do
    sign_in @member

    assert_api_response :get, 200, path_params: path_params do
      assert_equal false, parsed_body["items"].first["participating"]
      assert_equal false, parsed_body["items"].first["joinRequestPending"]
    end
  end

  test "GET names the fleet each tour belongs to" do
    sign_in @admin

    assert_api_response :get, 200, path_params: path_params do
      assert_equal @fleet.slug, parsed_body["items"].first["fleet"]["slug"]
    end
  end

  test "GET leaves another fleet's tours out" do
    create(:tour, fleet: create(:fleet), created_by: @admin)
    sign_in @admin

    assert_api_response :get, 200, path_params: path_params do
      assert_equal [@tour.id], parsed_body["items"].map { |item| item["id"] }
    end
  end

  # A standalone tour the same person organised has no fleet, so it must not be
  # swept into a fleet's list.
  test "GET leaves a standalone tour out" do
    create(:tour, created_by: @admin)
    sign_in @admin

    assert_api_response :get, 200, path_params: path_params do
      assert_equal [@tour.id], parsed_body["items"].map { |item| item["id"] }
    end
  end

  # FleetPolicy's relation scope is the fleets you belong to, so a fleet you
  # are not in does not resolve at all -- it never reaches `index?`.
  test "GET returns 404 for someone outside the fleet" do
    sign_in @outsider

    assert_api_response :get, 404, path_params: path_params
  end

  test "GET is refused when the feature is off" do
    Flipper.disable("tour_payouts")
    sign_in @admin

    assert_api_response :get, 403, path_params: path_params do
      assert_equal "forbidden", parsed_body["code"]
    end
  end

  # fleet_tours stacks on tour_payouts rather than replacing it, so the fleet
  # surface closes on its own while the standalone tool stays open.
  test "GET is refused when the fleet flag is off" do
    Flipper.disable("fleet_tours")
    sign_in @admin

    assert_api_response :get, 403, path_params: path_params do
      assert_equal "forbidden", parsed_body["code"]
    end
  end

  test "GET returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: path_params
  end
end
