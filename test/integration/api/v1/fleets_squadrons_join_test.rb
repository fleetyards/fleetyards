# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronsJoinTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{slug}/join" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Squadron slug"

    post("Join Fleet Squadron") do
      operationId "joinFleetSquadron"
      tags "FleetSquadrons"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful") do
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - an ordinary squadron is asked for, not joined") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @member = create(:user)
    @fleet = create(:fleet, :with_squadrons, members: [@member])
    @team = create(:fleet_squadron, fleet: @fleet, team: true)
    @squadron = create(:fleet_squadron, fleet: @fleet)
    @membership = @fleet.fleet_memberships.kept.find_by(user: @member)
  end

  test "POST join puts a member on a team at the default rank" do
    sign_in @member

    assert_api_response :post, 204, path_params: {fleetSlug: @fleet.slug, slug: @team.slug} do
      row = @team.fleet_squadron_memberships.find_by(fleet_membership: @membership)
      assert_equal "member", row.fleet_squadron_role.key
    end
  end

  test "POST join is refused for an ordinary squadron" do
    sign_in @member

    assert_api_response :post, 403, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug}

    refute @squadron.fleet_squadron_memberships.exists?(fleet_membership: @membership)
  end

  test "POST join twice is a validation error" do
    create(:fleet_squadron_membership, fleet_squadron: @team, fleet_membership: @membership)
    sign_in @member

    assert_api_response :post, 400, path_params: {fleetSlug: @fleet.slug, slug: @team.slug}
  end

  test "POST join needs a session" do
    assert_api_response :post, 401, path_params: {fleetSlug: @fleet.slug, slug: @team.slug}
  end

  test "POST join is not found for an unknown squadron" do
    sign_in @member

    assert_api_response :post, 404, path_params: {fleetSlug: @fleet.slug, slug: "no-such-squadron-0"}
  end
end
