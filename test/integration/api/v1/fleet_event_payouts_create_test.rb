# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetEventPayoutsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{fleetEventSlug}/payouts" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "fleetEventSlug", in: :path, schema: {type: :string}

    post("Open a payout ledger on a fleet event") do
      operationId "createFleetEventPayoutLedger"
      tags "Payouts"
      consumes "application/json"
      produces "application/json"

      request_body schema: ::V1::Schemas::Inputs::PayoutLedgerCreateInput, required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Payouts::PayoutLedger
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    get("Show the payout ledger of a fleet event") do
      operationId "fleetEventPayoutLedger"
      tags "Payouts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::PayoutLedger
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "no ledger yet") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("tour_payouts")
    Flipper.enable("fleet_mission_builder")

    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @event = create(:fleet_event, :active, fleet: @fleet, created_by: @admin)
  end

  def path_params
    {fleetSlug: @fleet.slug, fleetEventSlug: @event.slug}
  end

  test "POST seeds the participants from the event's signups" do
    slot = create(:fleet_event_slot, slottable: create(:fleet_event_team, fleet_event: @event))
    membership = @fleet.fleet_memberships.find_by(user_id: @member.id)
    create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: slot, fleet_membership: membership)

    sign_in @admin

    assert_api_response :post, 201, path_params: path_params do
      ledger = PayoutLedger.find(parsed_body["id"])
      assert_equal [@member.id], ledger.payout_participants.pluck(:user_id)
      assert_equal "FleetEvent", parsed_body["subjectType"]
    end
  end

  test "POST does not seed a withdrawn signup" do
    slot = create(:fleet_event_slot, slottable: create(:fleet_event_team, fleet_event: @event))
    membership = @fleet.fleet_memberships.find_by(user_id: @member.id)
    create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: slot,
      fleet_membership: membership, status: "withdrawn")

    sign_in @admin

    assert_api_response :post, 201, path_params: path_params do
      assert_empty PayoutLedger.find(parsed_body["id"]).payout_participants
    end
  end

  test "POST is refused for a plain member" do
    sign_in @member

    assert_api_response :post, 403, path_params: path_params
  end

  test "POST is refused when the feature is off for the fleet" do
    Flipper.disable("tour_payouts")
    sign_in @admin

    assert_api_response :post, 403, path_params: path_params
  end

  test "GET returns 404 before a ledger is opened" do
    sign_in @admin

    assert_api_response :get, 404, path_params: path_params
  end

  test "GET returns the ledger once it exists" do
    ledger = create(:payout_ledger, subject: @event)
    sign_in @admin

    assert_api_response :get, 200, path_params: path_params do
      assert_equal ledger.id, parsed_body["id"]
    end
  end

  test "GET returns 401 when not signed in" do
    create(:payout_ledger, subject: @event)

    assert_api_response :get, 401, path_params: path_params
  end
end
