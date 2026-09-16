# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MeSupporterContributionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  COLLECTION_PATH = "/me/supporter/contributions"
  MEMBER_PATH = "/me/supporter/contributions/{id}"

  api_path COLLECTION_PATH do
    get("List my supporter contributions") do
      operationId "mySupporterContributions"
      tags "Me Supporter"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:read"]},
        {OpenId: ["user", "user:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::MySupporterContributionsList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path MEMBER_PATH do
    parameter name: :id, in: :path, required: true, schema: {type: :string, format: :uuid}

    put("Nominate the fleet a contribution is for") do
      operationId "nominateFleetForSupporterContribution"
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
        schema ::V1::Schemas::MySupporterContribution
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @membership = create(:fleet_membership, :accepted)
    @supporter = @membership.user
    @fleet = @membership.fleet
    @contribution = create(:supporter_contribution, user: @supporter)
  end

  test "GET /me/supporter/contributions lists only my own" do
    create(:supporter_contribution, user: create(:user))
    create(:supporter_contribution, user: nil)
    sign_in @supporter

    assert_api_response :get, 200, api_path: COLLECTION_PATH do
      assert_equal [@contribution.id], parsed_body.map { |row| row["id"] }
    end
  end

  test "GET /me/supporter/contributions omits the fleet until one is nominated" do
    sign_in @supporter

    assert_api_response :get, 200, api_path: COLLECTION_PATH do
      refute parsed_body.first.key?("fleet")
    end

    @contribution.update!(fleet: @fleet)

    assert_api_response :get, 200, api_path: COLLECTION_PATH do
      assert_equal @fleet.slug, parsed_body.first.dig("fleet", "slug")
    end
  end

  test "GET /me/supporter/contributions is unauthorized when signed out" do
    assert_api_response :get, 401, api_path: COLLECTION_PATH
  end

  test "PUT /me/supporter/contributions/{id} nominates a fleet" do
    sign_in @supporter

    assert_api_response :put, 200, api_path: MEMBER_PATH, path_params: {id: @contribution.id}, body: {fleetId: @fleet.id} do
      assert_equal @fleet.id, parsed_body.dig("fleet", "id")
    end

    assert_equal @fleet.id, @contribution.reload.fleet_id
  end

  test "PUT /me/supporter/contributions/{id} clears the nomination with an explicit null" do
    @contribution.update!(fleet: @fleet)
    sign_in @supporter

    assert_api_response :put, 200, api_path: MEMBER_PATH, path_params: {id: @contribution.id}, body: {fleetId: nil} do
      refute parsed_body.key?("fleet")
    end

    assert_nil @contribution.reload.fleet_id
  end

  test "PUT /me/supporter/contributions/{id} refuses a fleet I am not an accepted member of" do
    sign_in @supporter

    assert_api_response :put, 400, api_path: MEMBER_PATH, path_params: {id: @contribution.id}, body: {fleetId: create(:fleet).id}

    assert_nil @contribution.reload.fleet_id
  end

  # The scope is the authorization here, so somebody else's contribution has to
  # be missing rather than forbidden -- a 403 would confirm it exists.
  test "PUT /me/supporter/contributions/{id} cannot reach somebody else's contribution" do
    theirs = create(:supporter_contribution, user: create(:user))
    sign_in @supporter

    assert_api_response :put, 404, api_path: MEMBER_PATH, path_params: {id: theirs.id}, body: {fleetId: @fleet.id}

    assert_nil theirs.reload.fleet_id
  end

  test "PUT /me/supporter/contributions/{id} is unauthorized when signed out" do
    assert_api_response :put, 401, api_path: MEMBER_PATH, path_params: {id: @contribution.id}, body: {fleetId: @fleet.id}
  end

  test "PUT /me/supporter/contributions/{id} with an OAuth bearer token" do
    assert_api_response :put, 200,
      api_path: MEMBER_PATH,
      path_params: {id: @contribution.id},
      body: {fleetId: @fleet.id},
      headers: oauth_headers_for(@supporter, scopes: ["user", "user:write"])
  end
end
