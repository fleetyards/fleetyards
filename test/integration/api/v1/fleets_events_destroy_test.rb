# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{slug}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    delete("Archive Fleet Event") do
      operationId "destroyFleetEvent"
      tags "Fleet Events"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful - archived") do
        schema ::V1::Schemas::Fleets::Events::FleetEventExtended
      end

      response(204, "successful - permanent delete on already-archived event") do
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)
  end

  # A published event is kept: people may have signed up to it, so deleting one
  # archives it and a second delete is what finally removes it.
  test "DELETE /fleets/:slug/events/:slug archives a published event" do
    published = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)
    sign_in @admin

    assert_api_response :delete, 200,
      path_params: {fleetSlug: @fleet.slug, slug: published.slug} do
      assert_equal true, parsed_body["archived"]
    end

    assert published.reload.archived?
  end

  # Nothing was ever announced and nobody can have signed up, so a draft goes
  # rather than being archived -- abandoning a create leaves no trace.
  test "DELETE /fleets/:slug/events/:slug deletes an unpublished event outright" do
    sign_in @admin

    assert_api_response :delete, 204,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug}

    assert_raises(ActiveRecord::RecordNotFound) { @fleet_event.reload }
  end

  test "DELETE /fleets/:slug/events/:slug permanently deletes an already-archived event" do
    archived = create(:fleet_event, fleet: @fleet, created_by: @admin, archived_at: Time.current)
    sign_in @admin

    assert_api_response :delete, 204,
      path_params: {fleetSlug: @fleet.slug, slug: archived.slug}

    assert_raises(ActiveRecord::RecordNotFound) { archived.reload }
  end

  test "DELETE /fleets/:slug/events/:slug with OAuth bearer token" do
    published = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)

    assert_api_response :delete, 200,
      path_params: {fleetSlug: @fleet.slug, slug: published.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "DELETE /fleets/:slug/events/:slug returns 401 for OAuth token with wrong scope" do
    assert_api_response :delete, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "DELETE /fleets/:slug/events/:slug returns 401 when not signed in" do
    assert_api_response :delete, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug}
  end
end
