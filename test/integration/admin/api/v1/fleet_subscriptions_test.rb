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

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
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

    get("Show a Fleet Subscription") do
      operationId "adminFleetSubscription"
      tags "FleetSubscriptions"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::FleetSubscription
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

    delete("Remove a Fleet Subscription") do
      operationId "destroyFleetSubscription"
      tags "FleetSubscriptions"
      produces "application/json"

      response(204, "no content")

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

  test "every action is unauthorized when signed out" do
    subscription = create(:fleet_subscription, fleet: @fleet)

    assert_api_response :get, 401, api_path: COLLECTION_PATH
    assert_api_response :post, 401, api_path: COLLECTION_PATH,
      body: {fleetId: @fleet.id, startedAt: Date.current.iso8601}
    assert_api_response :get, 401, api_path: MEMBER_PATH, path_params: {id: subscription.id}
    assert_api_response :put, 401, api_path: MEMBER_PATH, path_params: {id: subscription.id},
      body: {endedAt: Date.current.iso8601}
    assert_api_response :delete, 401, api_path: MEMBER_PATH, path_params: {id: subscription.id}
  end

  # A seeded row moved to another fleet would keep pointing at a contribution
  # naming the first, and the next sync would open a second row for that fleet
  # and close the moved one. Closing and reopening is the coherent way.
  test "PUT cannot move a subscription to a different fleet" do
    subscription = create(:fleet_subscription, :seeded, fleet: @fleet)
    other = create(:fleet)
    sign_in @user

    assert_api_response :put, 200, api_path: MEMBER_PATH, path_params: {id: subscription.id},
      body: {fleetId: other.id, note: "tried to move it"}

    assert_equal @fleet.id, subscription.reload.fleet_id
    assert_equal "tried to move it", subscription.note
  end

  test "a conflict on update is reported as an update failure" do
    create(:fleet_subscription, fleet: @fleet)
    closed = create(:fleet_subscription, fleet: @fleet, started_at: Date.current - 10,
      ended_at: Date.current - 1)
    sign_in @user

    assert_api_response :put, 400, api_path: MEMBER_PATH, path_params: {id: closed.id},
      body: {endedAt: nil} do
      assert_equal "validation_error.fleet_subscription.update", parsed_body["code"]
    end
  end

  # The one action that removes an entitlement must not be the one nobody can
  # see afterwards: a version with no author is filtered out of the feed.
  test "DELETE records who removed it" do
    subscription = create(:fleet_subscription, fleet: @fleet)
    sign_in @user

    assert_api_response :delete, 204, api_path: MEMBER_PATH, path_params: {id: subscription.id}

    version = PaperTrail::Version.where(item_type: "FleetSubscription", item_id: subscription.id)
      .order(:created_at).last

    assert_equal "destroy", version.event
    assert_equal @user.id, version.author_id
  end

  # The admin surface writes subscriptions too, so it has to tell the fleet for
  # the same reason the reconciler does.
  test "POST tells the fleet's admins it now has the features" do
    fleet_admin = create(:user)
    fleet = create(:fleet, admins: [fleet_admin])
    sign_in @user

    assert_api_response :post, 201, api_path: COLLECTION_PATH,
      body: {fleetId: fleet.id, startedAt: Date.current.iso8601}

    assert Notification.exists?(user: fleet_admin, notification_type: "fleet_subscription_started")
  end

  test "PUT that closes one tells them it lapsed" do
    fleet_admin = create(:user)
    fleet = create(:fleet, admins: [fleet_admin])
    subscription = create(:fleet_subscription, fleet:, started_at: Date.current - 10)
    sign_in @user

    assert_api_response :put, 200, api_path: MEMBER_PATH, path_params: {id: subscription.id},
      body: {endedAt: Date.current.iso8601}

    assert Notification.exists?(user: fleet_admin, notification_type: "fleet_subscription_ended")
  end

  # Only the transition. A fleet told twice that it lapsed learns to ignore the
  # message.
  test "editing a closed subscription announces nothing" do
    fleet_admin = create(:user)
    fleet = create(:fleet, admins: [fleet_admin])
    subscription = create(:fleet_subscription, fleet:, started_at: Date.current - 10,
      ended_at: Date.current - 1)
    sign_in @user

    assert_api_response :put, 200, api_path: MEMBER_PATH, path_params: {id: subscription.id},
      body: {note: "corrected"}

    assert_empty Notification.where(notification_type: "fleet_subscription_ended")
  end

  test "reopening a closed subscription announces that it started" do
    fleet_admin = create(:user)
    fleet = create(:fleet, admins: [fleet_admin])
    subscription = create(:fleet_subscription, fleet:, started_at: Date.current - 10,
      ended_at: Date.current - 1)
    sign_in @user

    assert_api_response :put, 200, api_path: MEMBER_PATH, path_params: {id: subscription.id},
      body: {endedAt: nil}

    assert Notification.exists?(user: fleet_admin, notification_type: "fleet_subscription_started")
  end

  # Deleting an entitlement takes access away exactly as closing one does.
  test "DELETE tells the fleet it lost the features" do
    fleet_admin = create(:user)
    fleet = create(:fleet, admins: [fleet_admin])
    subscription = create(:fleet_subscription, fleet:, started_at: Date.current - 10)
    sign_in @user

    assert_api_response :delete, 204, api_path: MEMBER_PATH, path_params: {id: subscription.id}

    assert Notification.exists?(user: fleet_admin, notification_type: "fleet_subscription_ended")
  end

  test "deleting an already-closed subscription announces nothing" do
    fleet_admin = create(:user)
    fleet = create(:fleet, admins: [fleet_admin])
    subscription = create(:fleet_subscription, fleet:, started_at: Date.current - 10,
      ended_at: Date.current - 1)
    sign_in @user

    assert_api_response :delete, 204, api_path: MEMBER_PATH, path_params: {id: subscription.id}

    assert_empty Notification.where(notification_type: "fleet_subscription_ended")
  end

  # `ended_at` is permitted on create, so a grant can arrive already closed.
  test "POST of an already-closed grant announces nothing" do
    fleet_admin = create(:user)
    fleet = create(:fleet, admins: [fleet_admin])
    sign_in @user

    assert_api_response :post, 201, api_path: COLLECTION_PATH,
      body: {fleetId: fleet.id, startedAt: (Date.current - 10).iso8601,
             endedAt: (Date.current - 1).iso8601}

    assert_empty Notification.where(notification_type: "fleet_subscription_started")
  end

  test "POST of a future-dated grant announces nothing yet" do
    fleet_admin = create(:user)
    fleet = create(:fleet, admins: [fleet_admin])
    sign_in @user

    assert_api_response :post, 201, api_path: COLLECTION_PATH,
      body: {fleetId: fleet.id, startedAt: (Date.current + 7).iso8601}

    assert_empty Notification.where(notification_type: "fleet_subscription_started")
  end
end
