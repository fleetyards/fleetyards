# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FleetSubscriptionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  COLLECTION_PATH = "/fleet-subscriptions"
  MEMBER_PATH = "/fleet-subscriptions/{id}"

  api_path COLLECTION_PATH do
    get("List Fleet Subscriptions") do
      operationId "adminFleetSubscriptions"
      tags "FleetSubscriptions"
      produces "application/json"

      parameter ::Shared::V1::Parameters::PageParameter
      parameter ::Shared::V1::Parameters::SortingParameter
      parameter name: "q", in: :query,
        schema: {"$ref": "#/components/schemas/FleetSubscriptionQuery"},
        style: :deepObject, explode: true, required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::FleetSubscriptions
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    post("Open a Fleet Subscription") do
      operationId "createFleetSubscription"
      tags "FleetSubscriptions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::FleetSubscriptionInput

      response(201, "created") do
        schema ::Admin::V1::Schemas::FleetSubscription
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path MEMBER_PATH do
    parameter name: :id, in: :path, required: true, schema: {type: :string, format: :uuid}

    get("Show a Fleet Subscription") do
      operationId "adminFleetSubscription"
      tags "FleetSubscriptions"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::FleetSubscription
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    put("Update a Fleet Subscription") do
      operationId "updateFleetSubscription"
      tags "FleetSubscriptions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::FleetSubscriptionInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::FleetSubscription
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    delete("Remove a Fleet Subscription") do
      operationId "destroyFleetSubscription"
      tags "FleetSubscriptions"
      produces "application/json"

      response(204, "no content")

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:supporters])
    @fleet = create(:fleet)
  end

  test "POST opens a manual subscription the reconciler will not close" do
    sign_in @user

    assert_api_response :post, 201, api_path: COLLECTION_PATH,
      body: {fleetId: @fleet.id, startedAt: Date.current.iso8601, note: "Partner org"} do
      assert_equal "manual", parsed_body["grantedVia"]
      assert parsed_body["open"]
      assert_equal @fleet.slug, parsed_body.dig("fleet", "slug")
    end

    subscription = FleetSubscription.sole

    assert_nil subscription.supporter_contribution_id,
      "a comp must have no contribution behind it, or Sync would close it"
  end

  # The whole point of `granted_via: manual` (D2).
  test "a subscription opened here survives a reconciliation" do
    sign_in @user

    assert_api_response :post, 201, api_path: COLLECTION_PATH,
      body: {fleetId: @fleet.id, startedAt: Date.current.iso8601}

    Subscriptions::Sync.call

    assert FleetSubscription.sole.reload.open?
  end

  test "POST cannot claim a grant came from a contribution" do
    contribution = create(:supporter_contribution)
    sign_in @user

    assert_api_response :post, 201, api_path: COLLECTION_PATH,
      body: {fleetId: @fleet.id, startedAt: Date.current.iso8601} do
      assert_equal "manual", parsed_body["grantedVia"]
    end

    refute_equal contribution.id, FleetSubscription.sole.supporter_contribution_id
  end

  # A readable error rather than a 500 from the partial unique index: two
  # admins comping the same fleet at once is exactly the case.
  test "POST refuses a second open subscription for one fleet" do
    create(:fleet_subscription, fleet: @fleet)
    sign_in @user

    assert_api_response :post, 400, api_path: COLLECTION_PATH,
      body: {fleetId: @fleet.id, startedAt: Date.current.iso8601}

    assert_equal 1, @fleet.fleet_subscriptions.count
  end

  test "PUT closes a subscription by dating it rather than destroying it" do
    subscription = create(:fleet_subscription, fleet: @fleet, started_at: Date.current - 10)
    sign_in @user

    assert_api_response :put, 200, api_path: MEMBER_PATH, path_params: {id: subscription.id},
      body: {endedAt: Date.current.iso8601} do
      refute parsed_body["open"]
    end

    assert_equal Date.current, subscription.reload.ended_at
    assert FleetSubscription.exists?(subscription.id)
  end

  test "PUT refuses an end date before the start" do
    subscription = create(:fleet_subscription, fleet: @fleet, started_at: Date.current)
    sign_in @user

    assert_api_response :put, 400, api_path: MEMBER_PATH, path_params: {id: subscription.id},
      body: {endedAt: (Date.current - 1).iso8601}

    assert_nil subscription.reload.ended_at
  end

  test "every write records the admin who made it" do
    subscription = create(:fleet_subscription, fleet: @fleet)
    sign_in @user

    assert_api_response :put, 200, api_path: MEMBER_PATH, path_params: {id: subscription.id},
      body: {endedAt: Date.current.iso8601, updateReason: "support ticket"}

    version = subscription.reload.versions.last

    assert_includes version.object_changes.keys, "ended_at"
    assert_equal @user.id, version.author_id
  end

  test "GET lists subscriptions and filters by fleet and openness" do
    open_one = create(:fleet_subscription, fleet: @fleet)
    closed = create(:fleet_subscription, started_at: Date.current - 10, ended_at: Date.current - 1)
    sign_in @user

    assert_api_response :get, 200, api_path: COLLECTION_PATH do
      assert_equal 2, parsed_body["items"].size
    end

    assert_api_response :get, 200, api_path: COLLECTION_PATH, params: {q: {endedAtNull: true}} do
      assert_equal [open_one.id], parsed_body["items"].map { |row| row["id"] }
    end

    assert_api_response :get, 200, api_path: COLLECTION_PATH, params: {q: {fleetIdEq: closed.fleet_id}} do
      assert_equal [closed.id], parsed_body["items"].map { |row| row["id"] }
    end
  end

  test "GET filters by how the grant was made" do
    comp = create(:fleet_subscription, fleet: @fleet, granted_via: "manual")
    seeded = create(:fleet_subscription, :seeded)
    sign_in @user

    assert_api_response :get, 200, api_path: COLLECTION_PATH, params: {q: {grantedViaEq: "manual"}} do
      assert_equal [comp.id], parsed_body["items"].map { |row| row["id"] }
    end

    assert_api_response :get, 200, api_path: COLLECTION_PATH, params: {q: {grantedViaEq: "contribution"}} do
      assert_equal [seeded.id], parsed_body["items"].map { |row| row["id"] }
    end
  end

  # Whether closing by hand will stick, or be reopened by the next sync.
  test "GET shows the contribution behind a seeded subscription and nothing on a comp" do
    create(:fleet_subscription, :seeded)
    sign_in @user

    assert_api_response :get, 200, api_path: COLLECTION_PATH do
      assert parsed_body["items"].first.key?("supporterContribution")
    end

    FleetSubscription.destroy_all
    create(:fleet_subscription, fleet: @fleet, granted_via: "manual")

    assert_api_response :get, 200, api_path: COLLECTION_PATH do
      refute parsed_body["items"].first.key?("supporterContribution")
    end
  end

  test "DELETE removes a grant that should never have existed" do
    subscription = create(:fleet_subscription, fleet: @fleet)
    sign_in @user

    assert_api_response :delete, 204, api_path: MEMBER_PATH, path_params: {id: subscription.id}

    refute FleetSubscription.exists?(subscription.id)
  end

  test "an admin without the supporters section reaches none of it" do
    sign_in create(:admin_user, resource_access: [:fleets])
    subscription = create(:fleet_subscription, fleet: @fleet)

    assert_api_response :get, 403, api_path: COLLECTION_PATH
    assert_api_response :post, 403, api_path: COLLECTION_PATH,
      body: {fleetId: @fleet.id, startedAt: Date.current.iso8601}
    assert_api_response :get, 403, api_path: MEMBER_PATH, path_params: {id: subscription.id}
    assert_api_response :put, 403, api_path: MEMBER_PATH, path_params: {id: subscription.id},
      body: {endedAt: Date.current.iso8601}
    assert_api_response :delete, 403, api_path: MEMBER_PATH, path_params: {id: subscription.id}
  end

  test "GET a subscription that does not exist is a 404" do
    sign_in @user

    assert_api_response :get, 404, api_path: MEMBER_PATH,
      path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end
end
