# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarPlansTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  READ_SECURITY = [
    {SessionCookie: []},
    {Oauth2: ["hangar", "hangar:read"]},
    {OpenId: ["hangar", "hangar:read"]}
  ].freeze

  WRITE_SECURITY = [
    {SessionCookie: []},
    {Oauth2: ["hangar", "hangar:write"]},
    {OpenId: ["hangar", "hangar:write"]}
  ].freeze

  api_path "/hangar/plans" do
    get("Hangar Plans") do
      operationId "hangarPlans"
      tags "HangarPlans"
      produces "application/json"
      security READ_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Hangar::Plans::HangarPlansList }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "feature disabled") { schema ::Shared::V1::Schemas::StandardError }
    end

    post("Create Hangar Plan") do
      operationId "createHangarPlan"
      tags "HangarPlans"
      consumes "application/json"
      produces "application/json"
      security WRITE_SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarPlanCreateInput

      response(201, "successful") { schema ::V1::Schemas::Hangar::Plans::HangarPlan }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "source plan not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/hangar/plans/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    get("Hangar Plan") do
      operationId "hangarPlan"
      tags "HangarPlans"
      produces "application/json"
      security READ_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Hangar::Plans::HangarPlan }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    put("Update Hangar Plan") do
      operationId "updateHangarPlan"
      tags "HangarPlans"
      consumes "application/json"
      produces "application/json"
      security WRITE_SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarPlanUpdateInput

      response(200, "successful") { schema ::V1::Schemas::Hangar::Plans::HangarPlan }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    delete("Destroy Hangar Plan") do
      operationId "destroyHangarPlan"
      tags "HangarPlans"
      produces "application/json"
      security WRITE_SECURITY

      response(200, "successful") { schema ::V1::Schemas::SuccessResponse }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    Flipper.enable(:hangar_planner)
    @user = create(:user)
    @gladius = create(:model, name: "Gladius", pledge_price: 90)
    @plan = create(:hangar_plan, user: @user, name: "Endgame")
  end

  test "GET /hangar/plans lists the user's plans only" do
    create(:hangar_plan)
    sign_in @user

    assert_api_response :get, 200, api_path: "/hangar/plans" do
      assert_equal ["Endgame"], parsed_body.pluck("name")
    end
  end

  test "GET /hangar/plans is forbidden while the feature is off" do
    Flipper.disable(:hangar_planner)
    sign_in @user

    assert_api_response :get, 403, api_path: "/hangar/plans"
  end

  test "GET /hangar/plans returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: "/hangar/plans"
  end

  test "POST /hangar/plans creates an empty plan" do
    sign_in @user

    assert_api_response :post, 201, api_path: "/hangar/plans", body: {name: "Mining", startingCredit: 120} do
      assert_equal "Mining", parsed_body["name"]
      assert_in_delta 120.0, parsed_body["startingCredit"]
      assert_empty parsed_body["slots"]
    end
  end

  test "POST /hangar/plans starts from the hangar" do
    vehicle = create(:vehicle, user: @user, model: @gladius)
    sign_in @user

    assert_no_changes -> { Vehicle.count } do
      assert_api_response :post, 201, api_path: "/hangar/plans", body: {name: "From hangar", source: "hangar"} do
        slot = parsed_body["slots"].first
        assert_equal "decided", slot["state"]
        assert_equal vehicle.id, slot.dig("candidates", 0, "acquisitions", 0, "sourceVehicleId")
      end
    end
  end

  test "POST /hangar/plans duplicates another plan" do
    @plan.slots.create!(label: "Fighter").candidates.create!(model: @gladius)
    sign_in @user

    assert_api_response :post, 201, api_path: "/hangar/plans", body: {name: "Copy", source: "plan", sourcePlanId: @plan.id} do
      assert_equal ["Fighter"], parsed_body["slots"].pluck("label")
    end
  end

  test "POST /hangar/plans cannot duplicate another user's plan" do
    sign_in @user

    assert_api_response :post, 404, api_path: "/hangar/plans",
      body: {name: "Copy", source: "plan", sourcePlanId: create(:hangar_plan).id}
  end

  test "POST /hangar/plans rejects a twenty-first plan" do
    (HangarPlan::MAX_PER_USER - 1).times { create(:hangar_plan, user: @user) }
    sign_in @user

    assert_api_response :post, 400, api_path: "/hangar/plans", body: {name: "One too many"}
  end

  test "POST /hangar/plans with OAuth bearer token" do
    assert_api_response :post, 201, api_path: "/hangar/plans",
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {name: "OAuth"}
  end

  test "GET /hangar/plans/:id returns the plan" do
    sign_in @user

    assert_api_response :get, 200, path_params: {id: @plan.id} do
      assert_equal "Endgame", parsed_body["name"]
      assert_not parsed_body["shared"]
    end
  end

  test "GET /hangar/plans/:id returns 404 for another user's plan" do
    sign_in create(:user)

    assert_api_response :get, 404, path_params: {id: @plan.id}
  end

  test "PUT /hangar/plans/:id updates the plan" do
    sign_in @user

    assert_api_response :put, 200, path_params: {id: @plan.id}, body: {name: "Renamed", description: "Notes"} do
      assert_equal "Renamed", parsed_body["name"]
      assert_equal "Notes", parsed_body["description"]
    end
  end

  test "PUT /hangar/plans/:id rejects a name the user already gave a plan" do
    create(:hangar_plan, user: @user, name: "Taken")
    sign_in @user

    assert_api_response :put, 400, path_params: {id: @plan.id}, body: {name: "Taken"}
  end

  test "DELETE /hangar/plans/:id removes the plan" do
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: @plan.id}

    assert_not HangarPlan.exists?(@plan.id)
  end

  test "DELETE /hangar/plans/:id returns 404 for another user's plan" do
    sign_in create(:user)

    assert_api_response :delete, 404, path_params: {id: @plan.id}
  end
end
