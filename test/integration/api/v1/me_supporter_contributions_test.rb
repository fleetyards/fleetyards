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

      response(403, "forbidden") do
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

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_subscriptions")

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

  # A nomination decides entitlement, so the change has to be answerable later.
  # The supporter is the whodunnit; `author_id` stays the admin-only field.
  test "PUT /me/supporter/contributions/{id} records who changed the nomination" do
    sign_in @supporter

    assert_difference -> { @contribution.versions.count }, 1 do
      assert_api_response :put, 200, api_path: MEMBER_PATH,
        path_params: {id: @contribution.id}, body: {fleetId: @fleet.id}
    end

    version = @contribution.reload.versions.last

    assert_includes version.object_changes.keys, "fleet_id"
    assert_equal [nil, @fleet.id], version.object_changes["fleet_id"]
    assert_equal @supporter.id, version.whodunnit
  end

  # The controller has no "leave it alone" branch, and this is why: the request
  # schema requires the key, so an omitted one never reaches it.
  test "PUT /me/supporter/contributions/{id} refuses a body with no fleetId" do
    @contribution.update!(fleet: @fleet)
    sign_in @supporter

    put "/api/v1/me/supporter/contributions/#{@contribution.id}",
      params: {}.to_json,
      headers: {"CONTENT_TYPE" => "application/json"}

    assert_response :bad_request
    assert_equal @fleet.id, @contribution.reload.fleet_id
  end

  # The premium work ships switched off, so until the transition is announced
  # neither surface exists for anybody.
  test "both endpoints are unavailable while the flag is off" do
    Flipper.disable("fleet_subscriptions")
    sign_in @supporter

    assert_api_response :get, 403, api_path: COLLECTION_PATH

    assert_api_response :put, 403, api_path: MEMBER_PATH,
      path_params: {id: @contribution.id}, body: {fleetId: @fleet.id}

    assert_nil @contribution.reload.fleet_id
  end

  # The flag check sits after the doorkeeper callbacks, so a signed-out caller
  # is still told to authenticate rather than that the feature is missing.
  test "a signed-out caller gets 401 rather than the feature gate" do
    Flipper.disable("fleet_subscriptions")

    assert_api_response :get, 401, api_path: COLLECTION_PATH
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
  # A nomination is not a payment event, and it is the other half of what the
  # reconciler answers to.
  test "PUT /me/supporter/contributions/{id} schedules a reconciliation" do
    Subscriptions::SyncJob.jobs.clear
    sign_in @supporter

    assert_api_response :put, 200, api_path: MEMBER_PATH,
      path_params: {id: @contribution.id}, body: {fleetId: @fleet.id}

    assert_equal 1, Subscriptions::SyncJob.jobs.size
  end

  test "a refused nomination schedules nothing" do
    Subscriptions::SyncJob.jobs.clear
    sign_in @supporter

    assert_api_response :put, 400, api_path: MEMBER_PATH,
      path_params: {id: @contribution.id}, body: {fleetId: create(:fleet).id}

    assert_empty Subscriptions::SyncJob.jobs
  end

  # The supporter's own action in their own settings. They know they did it,
  # and the fleet finds out when the reconciler acts on it -- if it does.
  test "PUT /me/supporter/contributions/{id} announces nothing by itself" do
    admin = create(:user)
    fleet = create(:fleet, admins: [admin])
    create(:fleet_membership, :accepted, user: @supporter, fleet:)
    sign_in @supporter

    assert_api_response :put, 200, api_path: MEMBER_PATH,
      path_params: {id: @contribution.id}, body: {fleetId: fleet.id}

    assert_empty Notification.where(notification_type: %w[fleet_subscription_started
      fleet_subscription_ended])
  end
end
