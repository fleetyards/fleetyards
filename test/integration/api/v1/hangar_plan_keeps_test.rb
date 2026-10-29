# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarPlanKeepsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/plans/{hangarPlanId}/keeps" do
    parameter name: "hangarPlanId", in: :path, schema: {type: :string, format: :uuid}, required: true

    post("Keep Hangar Plan Vehicles") do
      operationId "createHangarPlanKeep"
      tags "HangarPlans"
      consumes "application/json"
      produces "application/json"
      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarPlanKeepCreateInput

      response(201, "successful") { schema ::V1::Schemas::Hangar::Plans::HangarPlan }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
    end
  end

  setup do
    Flipper.enable(:hangar_planner)
    @user = create(:user)
    @plan = create(:hangar_plan, user: @user)
    @gladius = create(:model, name: "Gladius")
    sign_in @user
  end

  test "POST keeps ships as they are, without a slot" do
    gladii = create_list(:vehicle, 2, user: @user, model: @gladius)
    @plan.vehicle_marks.create!(vehicle: gladii.first)

    assert_api_response :post, 201, api_path: "/hangar/plans/{hangarPlanId}/keeps",
      path_params: {hangarPlanId: @plan.id}, body: {vehicleIds: gladii.map(&:id)} do
      assert_empty parsed_body["slots"]
      assert_equal gladii.map { |vehicle| [vehicle.id, "keep"] }.sort,
        parsed_body["vehicleMarks"].map { |mark| mark.values_at("vehicleId", "mark") }.sort
    end
  end

  test "POST rejects a ship the plan melts" do
    vehicle = create(:vehicle, user: @user, model: @gladius)
    create(:hangar_plan_melt, hangar_plan: @plan, vehicle:)

    assert_api_response :post, 400, api_path: "/hangar/plans/{hangarPlanId}/keeps",
      path_params: {hangarPlanId: @plan.id}, body: {vehicleIds: [vehicle.id]}
    assert_empty @plan.vehicle_marks.reload
  end

  test "POST rejects a ship of another user" do
    assert_api_response :post, 400, api_path: "/hangar/plans/{hangarPlanId}/keeps",
      path_params: {hangarPlanId: @plan.id}, body: {vehicleIds: [create(:vehicle).id]}
  end
end
