# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetHealthTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/health" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    get("Fleet Health") do
      operationId "fleetHealth"
      tags "Fleets"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Dashboard::FleetHealth
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
    @admin = create(:user, last_active_at: 1.hour.ago)
    @member = create(:user, last_active_at: 1.hour.ago)
    @gone = create(:user, username: "gone", last_active_at: 60.days.ago)
    @never = create(:user, username: "never", last_active_at: nil)
    @fleet = create(:fleet, admins: [@admin], members: [@member, @gone, @never])
  end

  test "GET health counts members who stopped showing up, longest gone first" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 2, parsed_body.dig("inactiveMembers", "count")
      assert_equal %w[never gone], parsed_body.dig("inactiveMembers", "sample").map { |row| row["username"] }
    end
  end

  test "GET health asks about verification only for a fleet with an RSI org" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_nil parsed_body["unverifiedMembers"]
    end

    @fleet.update_columns(rsi_sid: "MARU")
    @fleet.fleet_memberships.find_by(user: @admin).update_columns(verified: true)

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body.dig("unverifiedMembers", "count")
    end
  end

  test "GET health lists the roles nobody holds" do
    create(:fleet_role, fleet: @fleet, name: "Medic")

    sign_in @admin
    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_includes parsed_body["emptyRoles"].map { |role| role["name"] }, "Medic"
    end
  end

  test "GET health is refused to a plain member" do
    sign_in @member

    assert_api_response :get, 403, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET health returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end
end
