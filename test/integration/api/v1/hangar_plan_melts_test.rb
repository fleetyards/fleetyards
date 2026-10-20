# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarPlanMeltsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  SECURITY = [
    {SessionCookie: []},
    {Oauth2: ["hangar", "hangar:write"]},
    {OpenId: ["hangar", "hangar:write"]}
  ].freeze

  PLAN = ::V1::Schemas::Hangar::Plans::HangarPlan

  api_path "/hangar/plans/{hangarPlanId}/melts" do
    parameter name: "hangarPlanId", in: :path, schema: {type: :string, format: :uuid}, required: true

    post("Create Hangar Plan Melt") do
      operationId "createHangarPlanMelt"
      tags "HangarPlans"
      consumes "application/json"
      produces "application/json"
      security SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarPlanMeltCreateInput

      response(201, "successful") { schema PLAN }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
    end
  end

  api_path "/hangar/plans/{hangarPlanId}/melts/{id}" do
    parameter name: "hangarPlanId", in: :path, schema: {type: :string, format: :uuid}, required: true
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    put("Update Hangar Plan Melt") do
      operationId "updateHangarPlanMelt"
      tags "HangarPlans"
      consumes "application/json"
      produces "application/json"
      security SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarPlanMeltUpdateInput

      response(200, "successful") { schema PLAN }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
    end

    delete("Destroy Hangar Plan Melt") do
      operationId "destroyHangarPlanMelt"
      tags "HangarPlans"
      produces "application/json"
      security SECURITY

      response(200, "successful") { schema PLAN }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    Flipper.enable(:hangar_planner)
    @user = create(:user)
    @plan = create(:hangar_plan, user: @user)
    @vehicle = create(:vehicle, user: @user, model: create(:model, pledge_price: 250))
    sign_in @user
  end

  test "POST melts a ship for today's store price" do
    assert_api_response :post, 201, api_path: "/hangar/plans/{hangarPlanId}/melts",
      path_params: {hangarPlanId: @plan.id}, body: {vehicleId: @vehicle.id} do
      melt = parsed_body["melts"].first
      assert_in_delta 250.0, melt["value"]
      assert melt["estimated"]
    end
  end

  test "POST rejects a ship of another user" do
    assert_api_response :post, 400, api_path: "/hangar/plans/{hangarPlanId}/melts",
      path_params: {hangarPlanId: @plan.id}, body: {vehicleId: create(:vehicle).id}
  end

  test "POST rejects a ship melted twice" do
    create(:hangar_plan_melt, hangar_plan: @plan, vehicle: @vehicle)

    assert_api_response :post, 400, api_path: "/hangar/plans/{hangarPlanId}/melts",
      path_params: {hangarPlanId: @plan.id}, body: {vehicleId: @vehicle.id}
  end

  test "PUT records what the user paid" do
    melt = create(:hangar_plan_melt, hangar_plan: @plan, vehicle: @vehicle)

    assert_api_response :put, 200, api_path: "/hangar/plans/{hangarPlanId}/melts/{id}",
      path_params: {hangarPlanId: @plan.id, id: melt.id}, body: {valueOverride: 180} do
      melt = parsed_body["melts"].first
      assert_in_delta 180.0, melt["value"]
      assert_not melt["estimated"]
    end
  end

  test "PUT rejects a negative value" do
    melt = create(:hangar_plan_melt, hangar_plan: @plan, vehicle: @vehicle)

    assert_api_response :put, 400, api_path: "/hangar/plans/{hangarPlanId}/melts/{id}",
      path_params: {hangarPlanId: @plan.id, id: melt.id}, body: {valueOverride: -5}
  end

  test "DELETE keeps the ship after all" do
    melt = create(:hangar_plan_melt, hangar_plan: @plan, vehicle: @vehicle)

    assert_api_response :delete, 200, api_path: "/hangar/plans/{hangarPlanId}/melts/{id}",
      path_params: {hangarPlanId: @plan.id, id: melt.id} do
      assert_empty parsed_body["melts"]
    end
  end
end
