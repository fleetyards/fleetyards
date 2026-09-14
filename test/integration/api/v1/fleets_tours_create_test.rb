# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsToursCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/tours" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    post("Create Fleet Tour") do
      operationId "createFleetTour"
      tags "Tours"
      consumes "application/json"
      produces "application/json"

      request_body schema: ::V1::Schemas::Inputs::TourCreateInput, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["user:write"]},
        {OpenId: ["user:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Payouts::Tour
      end

      response(400, "invalid") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("tour_payouts")

    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
  end

  def path_params
    {fleetSlug: @fleet.slug}
  end

  test "POST creates a tour that belongs to the fleet" do
    sign_in @admin

    assert_api_response :post, 201, path_params: path_params, body: {title: "Jumptown Run"} do
      assert_equal @fleet.slug, parsed_body["fleet"]["slug"]
      assert_equal @fleet.id, Tour.find(parsed_body["id"]).fleet_id
    end
  end

  test "POST opens the ledger with the organiser on it" do
    sign_in @admin

    assert_api_response :post, 201, path_params: path_params, body: {title: "Jumptown Run"} do
      tour = Tour.find(parsed_body["id"])

      assert_not_nil parsed_body["payoutLedgerId"]
      assert_equal [@admin.id], tour.payout_ledger.payout_participants.pluck(:user_id)
    end
  end

  # `fleet:payouts:create` is what the default member role carries, and
  # organising a trip is exactly what it is for.
  test "POST is allowed for a plain member" do
    sign_in @member

    assert_api_response :post, 201, path_params: path_params, body: {title: "Member Run"}
  end

  test "POST is refused for someone whose role has no payout privileges" do
    stripped = @fleet.fleet_roles.find_by(name: "Member")
    stripped.update!(resource_access: stripped.resource_access - PayoutLedger::AVAILABLE_PRIVILEGES)

    sign_in @member

    assert_api_response :post, 403, path_params: path_params, body: {title: "Member Run"}
  end

  test "POST is refused when the feature is off" do
    Flipper.disable("tour_payouts")
    sign_in @admin

    assert_api_response :post, 403, path_params: path_params, body: {title: "Jumptown Run"}
  end

  test "POST rejects a tour with no title" do
    sign_in @admin

    assert_api_response :post, 400, path_params: path_params, body: {title: ""}
  end

  test "POST returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: path_params, body: {title: "Jumptown Run"}
  end
end
