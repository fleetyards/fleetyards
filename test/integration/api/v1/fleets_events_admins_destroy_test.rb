# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsAdminsDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{slug}/admins/{id}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}
    parameter name: "id", in: :path, schema: {type: :string}

    delete("Revoke per-event admin/moderator role") do
      operationId "destroyFleetEventAdmin"
      tags "Fleet Event Admins"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful") do
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @other = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@other])
    @fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)
    @granted = @fleet_event.fleet_event_admins.create!(user: @other, role: "admin", granted_by: @admin)
  end

  test "DELETE /fleets/:slug/events/:slug/admins/:id revokes the role" do
    sign_in @admin

    assert_api_response :delete, 204,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug, id: @granted.id}

    assert_raises(ActiveRecord::RecordNotFound) { @granted.reload }
  end

  test "DELETE /fleets/:slug/events/:slug/admins/:id with OAuth bearer token" do
    assert_api_response :delete, 204,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug, id: @granted.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "DELETE /fleets/:slug/events/:slug/admins/:id returns 401 for OAuth token with wrong scope" do
    assert_api_response :delete, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug, id: @granted.id},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "DELETE /fleets/:slug/events/:slug/admins/:id returns 401 when not signed in" do
    assert_api_response :delete, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug, id: @granted.id}
  end
end
