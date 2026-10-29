# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarPlanVehicleMarksTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  SECURITY = [
    {SessionCookie: []},
    {Oauth2: ["hangar", "hangar:write"]},
    {OpenId: ["hangar", "hangar:write"]}
  ].freeze

  PLAN = ::V1::Schemas::Hangar::Plans::HangarPlan

  api_path "/hangar/plans/{hangarPlanId}/vehicle-marks" do
    parameter name: "hangarPlanId", in: :path, schema: {type: :string, format: :uuid}, required: true

    post("Create Hangar Plan Vehicle Mark") do
      operationId "createHangarPlanVehicleMark"
      tags "HangarPlans"
      consumes "application/json"
      produces "application/json"
      security SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarPlanVehicleMarkCreateInput

      response(201, "successful") { schema PLAN }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
    end
  end

  api_path "/hangar/plans/{hangarPlanId}/vehicle-marks/{id}" do
    parameter name: "hangarPlanId", in: :path, schema: {type: :string, format: :uuid}, required: true
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    put("Update Hangar Plan Vehicle Mark") do
      operationId "updateHangarPlanVehicleMark"
      tags "HangarPlans"
      consumes "application/json"
      produces "application/json"
      security SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarPlanVehicleMarkUpdateInput

      response(200, "successful") { schema PLAN }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
    end

    delete("Destroy Hangar Plan Vehicle Mark") do
      operationId "destroyHangarPlanVehicleMark"
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
    @vehicle = create(:vehicle, user: @user)
    sign_in @user
  end

  test "POST marks a ship to change" do
    assert_api_response :post, 201, api_path: "/hangar/plans/{hangarPlanId}/vehicle-marks",
      path_params: {hangarPlanId: @plan.id}, body: {vehicleId: @vehicle.id, mark: "change"} do
      assert_equal [[@vehicle.id, "change"]], parsed_body["vehicleMarks"].map { |mark| mark.values_at("vehicleId", "mark") }
    end
  end

  test "POST rejects a ship of another user" do
    assert_api_response :post, 400, api_path: "/hangar/plans/{hangarPlanId}/vehicle-marks",
      path_params: {hangarPlanId: @plan.id}, body: {vehicleId: create(:vehicle).id, mark: "change"}
  end

  test "PUT turns a pending ship into one to change" do
    mark = @plan.vehicle_marks.create!(vehicle: @vehicle)

    assert_api_response :put, 200, api_path: "/hangar/plans/{hangarPlanId}/vehicle-marks/{id}",
      path_params: {hangarPlanId: @plan.id, id: mark.id}, body: {mark: "change"} do
      assert_equal ["change"], parsed_body["vehicleMarks"].pluck("mark")
    end
  end

  test "DELETE leaves the ship to the plan" do
    mark = @plan.vehicle_marks.create!(vehicle: @vehicle)

    assert_api_response :delete, 200, api_path: "/hangar/plans/{hangarPlanId}/vehicle-marks/{id}",
      path_params: {hangarPlanId: @plan.id, id: mark.id} do
      assert_empty parsed_body["vehicleMarks"]
    end
  end
end
