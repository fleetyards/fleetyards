# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetAlliancesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  ACCEPT_PATH = "/fleets/{fleet_slug}/allies/{ally_slug}/accept"
  DECLINE_PATH = "/fleets/{fleet_slug}/allies/{ally_slug}/decline"
  IGNORE_PATH = "/fleets/{fleet_slug}/allies/{ally_slug}/ignore"

  READ_SECURITY = [
    {SessionCookie: []},
    {Oauth2: ["fleet", "fleet:read"]},
    {OpenId: ["fleet", "fleet:read"]}
  ].freeze

  WRITE_SECURITY = [
    {SessionCookie: []},
    {Oauth2: ["fleet", "fleet:write"]},
    {OpenId: ["fleet", "fleet:write"]}
  ].freeze

  api_path "/fleets/{fleet_slug}/allies" do
    parameter name: "fleet_slug", in: :path, schema: {type: :string}, description: "The acting fleet's slug"

    get("Fleet Allies") do
      operationId "fleetAllies"
      tags "FleetAllies"
      produces "application/json"

      parameter name: "state", in: :query, required: false,
        schema: ::V1::Schemas::Enums::RelationshipStateEnum,
        description: "Which state to list, as this fleet sees it. Defaults to accepted."
      parameter name: "direction", in: :query, required: false,
        schema: ::V1::Schemas::Enums::RelationshipDirectionEnum,
        description: "Limit to requests this fleet sent, or ones it was sent"
      parameter name: "page", in: :query, required: false, schema: {type: :integer}
      parameter name: "limit", in: :query, required: false, schema: {type: :integer}

      security READ_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Fleets::FleetAlliancesList }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    post("Send Alliance Request") do
      operationId "createFleetAlliance"
      tags "FleetAllies"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetAllianceCreateInput

      security WRITE_SECURITY

      response(201, "created") { schema ::V1::Schemas::Fleets::FleetAlliance }
      response(400, "bad request") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/fleets/{fleet_slug}/allies/{ally_slug}" do
    parameter name: "fleet_slug", in: :path, schema: {type: :string}, description: "The acting fleet's slug"
    parameter name: "ally_slug", in: :path, schema: {type: :string}, description: "The other fleet's slug"

    get("Fleet Alliance") do
      operationId "fleetAlliance"
      tags "FleetAllies"
      produces "application/json"

      security READ_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Fleets::FleetAlliance }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    delete("Withdraw a request, or end an alliance") do
      operationId "destroyFleetAlliance"
      tags "FleetAllies"

      security WRITE_SECURITY

      response(204, "removed")
      response(400, "bad request") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  %w[accept decline ignore].each do |action|
    api_path "/fleets/{fleet_slug}/allies/{ally_slug}/#{action}" do
      parameter name: "fleet_slug", in: :path, schema: {type: :string}, description: "The acting fleet's slug"
      parameter name: "ally_slug", in: :path, schema: {type: :string}, description: "The other fleet's slug"

      put("#{action.capitalize} Alliance Request") do
        operationId "#{action}FleetAlliance"
        tags "FleetAllies"
        produces "application/json"

        security WRITE_SECURITY

        response(200, "successful") { schema ::V1::Schemas::Fleets::FleetAlliance }
        response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
        response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
        response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
      end
    end
  end

  setup do
    Flipper.enable("fleet_allies")

    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @other_fleet = create(:fleet, created_by: create(:user).id)
  end

  def slugs(ally = @other_fleet)
    {fleet_slug: @fleet.slug, ally_slug: ally.slug}
  end

  test "POST sends an alliance request" do
    sign_in @admin

    assert_api_response :post, 201, path_params: {fleet_slug: @fleet.slug}, body: {slug: @other_fleet.slug} do
      assert_equal "pending", parsed_body["state"]
      assert_equal "outgoing", parsed_body["direction"]
      assert_equal @other_fleet.slug, parsed_body.dig("fleet", "slug")
    end
  end

  test "POST accepts a request the other fleet already sent" do
    create(:fleet_alliance, requester: @other_fleet, addressee: @fleet)
    sign_in @admin

    assert_api_response :post, 201, path_params: {fleet_slug: @fleet.slug}, body: {slug: @other_fleet.slug} do
      assert_equal "accepted", parsed_body["state"]
    end

    assert @fleet.reload.allied_with?(@other_fleet)
  end

  test "POST with a fleet allying itself is refused" do
    sign_in @admin

    assert_api_response :post, 400, path_params: {fleet_slug: @fleet.slug}, body: {slug: @fleet.slug}
  end

  test "GET lists accepted allies" do
    create(:fleet_alliance, :accepted, requester: @fleet, addressee: @other_fleet)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleet_slug: @fleet.slug} do
      assert_equal [@other_fleet.slug], parsed_body["items"].map { |row| row.dig("fleet", "slug") }
    end
  end

  test "PUT accept allies the two fleets" do
    create(:fleet_alliance, requester: @other_fleet, addressee: @fleet)
    sign_in @admin

    assert_api_response :put, 200, api_path: ACCEPT_PATH, path_params: slugs do
      assert_equal "accepted", parsed_body["state"]
    end

    assert @fleet.reload.allied_with?(@other_fleet)
  end

  test "PUT decline turns it away" do
    alliance = create(:fleet_alliance, requester: @other_fleet, addressee: @fleet)
    sign_in @admin

    assert_api_response :put, 200, api_path: DECLINE_PATH, path_params: slugs

    assert alliance.reload.declined?
  end

  test "PUT ignore hides it, and the sending fleet sees no change" do
    alliance = create(:fleet_alliance, requester: @other_fleet, addressee: @fleet)
    sign_in @admin

    assert_api_response :put, 200, api_path: IGNORE_PATH, path_params: slugs

    assert alliance.reload.ignored?
  end

  test "DELETE ends an accepted alliance" do
    create(:fleet_alliance, :accepted, requester: @fleet, addressee: @other_fleet)
    sign_in @admin

    assert_api_response :delete, 204, path_params: slugs
    assert_nil FleetAlliance.between(@fleet, @other_fleet)
  end

  # Alliances are an admin act, and an ordinary member holds none
  # of it.
  test "a plain member can neither read nor send" do
    member = create(:user)
    create(:fleet_membership, :accepted, fleet: @fleet, user: member,
      fleet_role: @fleet.fleet_roles.ranked.last)
    sign_in member

    assert_api_response :get, 403, path_params: {fleet_slug: @fleet.slug}
    assert_api_response :post, 403, path_params: {fleet_slug: @fleet.slug}, body: {slug: @other_fleet.slug}
  end

  test "an officer can read the list and cannot change it" do
    officer = create(:user)
    create(:fleet_membership, :accepted, fleet: @fleet, user: officer,
      fleet_role: @fleet.fleet_roles.ranked.second)
    sign_in officer

    assert_api_response :get, 200, path_params: {fleet_slug: @fleet.slug}
    assert_api_response :post, 403, path_params: {fleet_slug: @fleet.slug}, body: {slug: @other_fleet.slug}
  end

  # POST accepts an inbound request when it finds one, so it can complete an
  # alliance rather than only propose one. Accepting is the consequential half
  # and must not be reachable with the create privilege alone.
  test "a create-only role cannot accept an inbound request by posting" do
    creator = create(:user)
    role = create(:fleet_role, fleet: @fleet, name: "Recruiter",
      resource_access: ["fleet:allies:create"])
    create(:fleet_membership, :accepted, fleet: @fleet, user: creator, fleet_role: role)
    alliance = create(:fleet_alliance, requester: @other_fleet, addressee: @fleet)
    sign_in creator

    assert_api_response :post, 403, path_params: {fleet_slug: @fleet.slug}, body: {slug: @other_fleet.slug}
    assert alliance.reload.pending?
  end

  test "a create-only role can still send a request of its own" do
    creator = create(:user)
    role = create(:fleet_role, fleet: @fleet, name: "Recruiter",
      resource_access: ["fleet:allies:create"])
    create(:fleet_membership, :accepted, fleet: @fleet, user: creator, fleet_role: role)
    sign_in creator

    assert_api_response :post, 201, path_params: {fleet_slug: @fleet.slug}, body: {slug: @other_fleet.slug}
  end

  test "somebody outside the fleet gets nothing" do
    sign_in create(:user)

    assert_api_response :get, 403, path_params: {fleet_slug: @fleet.slug}
  end

  test "without a session it is unauthorized" do
    assert_api_response :get, 401, path_params: {fleet_slug: @fleet.slug}
  end

  test "it is forbidden with the feature off" do
    Flipper.disable("fleet_allies")
    sign_in @admin

    assert_api_response :get, 403, path_params: {fleet_slug: @fleet.slug}
  end

  test "an unknown fleet is a 404" do
    sign_in @admin

    assert_api_response :post, 404, path_params: {fleet_slug: @fleet.slug}, body: {slug: "no-such-fleet"}
  end
end
