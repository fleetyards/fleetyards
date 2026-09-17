# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MeSupportedFleetTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/me/supporter/fleet" do
    get("Show the fleet my donations support") do
      operationId "mySupportedFleet"
      tags "Me Supporter"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:read"]},
        {OpenId: ["user", "user:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::MySupportedFleet
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    put("Choose the fleet my donations support") do
      operationId "chooseMySupportedFleet"
      tags "Me Supporter"
      consumes "application/json"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:write"]},
        {OpenId: ["user", "user:write"]}
      ]

      request_body required: true, schema: ::V1::Schemas::Inputs::SupporterNominationInput

      response(200, "successful") do
        schema ::V1::Schemas::MySupportedFleet
      end

      response(400, "bad request") do
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
    Flipper.enable("fleet_subscriptions")

    @membership = create(:fleet_membership, :accepted)
    @supporter = @membership.user
    @fleet = @membership.fleet
  end

  # The whole point of this endpoint: answerable with no donation in sight.
  test "PUT /me/supporter/fleet works before any contribution exists" do
    assert_equal 0, @supporter.supporter_contributions.count
    sign_in @supporter

    assert_api_response :put, 200, body: {fleetId: @fleet.id} do
      assert_equal @fleet.id, parsed_body.dig("fleet", "id")
    end

    assert_equal @fleet.id, @supporter.reload.supported_fleet_id
  end

  test "GET /me/supporter/fleet omits the fleet until one is chosen" do
    sign_in @supporter

    assert_api_response :get, 200 do
      refute parsed_body.key?("fleet")
    end

    @supporter.update!(supported_fleet: @fleet)

    assert_api_response :get, 200 do
      assert_equal @fleet.slug, parsed_body.dig("fleet", "slug")
    end
  end

  # Somebody who never opens the setting still gets the fleet they marked as
  # their own, so the default works without being touched.
  test "GET /me/supporter/fleet falls back to the primary fleet" do
    @membership.update!(primary: true)
    sign_in @supporter

    assert_api_response :get, 200 do
      assert_equal @fleet.id, parsed_body.dig("fleet", "id")
      refute parsed_body["explicit"]
    end

    assert_nil @supporter.reload.supported_fleet_id
  end

  test "an explicit choice outranks the primary fleet" do
    other = create(:fleet_membership, :accepted, user: @supporter).fleet
    @membership.update!(primary: true)
    @supporter.update!(supported_fleet: other)
    sign_in @supporter

    assert_api_response :get, 200 do
      assert_equal other.id, parsed_body.dig("fleet", "id")
      assert parsed_body["explicit"]
    end
  end

  test "a primary flag on a membership that was discarded does not count" do
    @membership.update!(primary: true)
    @membership.discard
    sign_in @supporter

    assert_api_response :get, 200 do
      refute parsed_body.key?("fleet")
      refute parsed_body["explicit"]
    end
  end

  test "PUT /me/supporter/fleet clears the choice with an explicit null" do
    @supporter.update!(supported_fleet: @fleet)
    sign_in @supporter

    assert_api_response :put, 200, body: {fleetId: nil} do
      refute parsed_body.key?("fleet")
    end

    assert_nil @supporter.reload.supported_fleet_id
  end

  test "PUT /me/supporter/fleet refuses a fleet I am not an accepted member of" do
    sign_in @supporter

    assert_api_response :put, 400, body: {fleetId: create(:fleet).id}

    assert_nil @supporter.reload.supported_fleet_id
  end

  test "both verbs are unavailable while the flag is off" do
    Flipper.disable("fleet_subscriptions")
    sign_in @supporter

    assert_api_response :get, 403
    assert_api_response :put, 403, body: {fleetId: @fleet.id}

    assert_nil @supporter.reload.supported_fleet_id
  end

  test "GET /me/supporter/fleet is unauthorized when signed out" do
    assert_api_response :get, 401
  end

  test "PUT /me/supporter/fleet with an OAuth bearer token" do
    assert_api_response :put, 200,
      body: {fleetId: @fleet.id},
      headers: oauth_headers_for(@supporter, scopes: ["user", "user:write"])
  end
end
