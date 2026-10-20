# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarPlanAcquisitionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  SECURITY = [
    {SessionCookie: []},
    {Oauth2: ["hangar", "hangar:write"]},
    {OpenId: ["hangar", "hangar:write"]}
  ].freeze

  PLAN = ::V1::Schemas::Hangar::Plans::HangarPlan

  api_path "/hangar/plans/{hangarPlanId}/acquisitions" do
    parameter name: "hangarPlanId", in: :path, schema: {type: :string, format: :uuid}, required: true

    post("Create Hangar Plan Acquisition") do
      operationId "createHangarPlanAcquisition"
      tags "HangarPlans"
      consumes "application/json"
      produces "application/json"
      security SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarPlanAcquisitionCreateInput

      response(201, "successful") { schema PLAN }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/hangar/plans/{hangarPlanId}/acquisitions/{id}" do
    parameter name: "hangarPlanId", in: :path, schema: {type: :string, format: :uuid}, required: true
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    put("Update Hangar Plan Acquisition") do
      operationId "updateHangarPlanAcquisition"
      tags "HangarPlans"
      consumes "application/json"
      produces "application/json"
      security SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarPlanAcquisitionUpdateInput

      response(200, "successful") { schema PLAN }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
    end

    delete("Destroy Hangar Plan Acquisition") do
      operationId "destroyHangarPlanAcquisition"
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
    @cutlass = create(:model, name: "Cutlass Black", pledge_price: 100)
    @constellation = create(:model, name: "Constellation", pledge_price: 250)
    @carrack = create(:model, name: "Carrack", pledge_price: 600)
    @slot = create(:hangar_plan_slot, hangar_plan: @plan)
    @candidate = create(:hangar_plan_candidate, slot: @slot, model: @carrack)
    sign_in @user
  end

  test "POST plans a store purchase upgraded twice, chaining each step on the last" do
    body = {
      candidateId: @candidate.id, startKind: "store", startModelId: @cutlass.id,
      steps: [
        {sourceKind: "store", toModelId: @constellation.id},
        {sourceKind: "store", toModelId: @carrack.id}
      ]
    }

    assert_api_response :post, 201, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: do
      acquisition = parsed_body.dig("slots", 0, "candidates", 0, "acquisitions", 0)
      assert_in_delta 100.0, acquisition["price"]
      assert_equal [150.0, 350.0], acquisition["steps"].pluck("price")
      assert_equal ["Cutlass Black", "Constellation"], acquisition["steps"].map { |step| step.dig("fromModel", "name") }
    end
  end

  test "POST keeps an owned ship" do
    vehicle = create(:vehicle, user: @user, model: @carrack)

    assert_api_response :post, 201, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: {candidateId: @candidate.id, startKind: "owned", sourceVehicleId: vehicle.id} do
      assert_equal vehicle.id, parsed_body.dig("slots", 0, "candidates", 0, "acquisitions", 0, "sourceVehicleId")
    end
  end

  test "POST uses an upgrade from the RSI hangar" do
    vehicle = create(:vehicle, user: @user, model: @constellation)
    ccu = create(:hangar_pledge_item, user: @user, kind: "ccu", name: "Upgrade - Constellation To Carrack")
    body = {
      candidateId: @candidate.id, startKind: "owned", sourceVehicleId: vehicle.id,
      steps: [{sourceKind: "owned_ccu", hangarPledgeItemId: ccu.id, toModelId: @carrack.id}]
    }

    assert_api_response :post, 201, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: do
      assert_in_delta 0.0, parsed_body.dig("slots", 0, "candidates", 0, "acquisitions", 0, "steps", 0, "price")
    end
  end

  test "POST rejects a chain that does not end on the slot's ship" do
    assert_api_response :post, 400, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: {candidateId: @candidate.id, startKind: "store", startModelId: @cutlass.id}
  end

  test "POST rejects another user's ship" do
    vehicle = create(:vehicle, model: @carrack)

    assert_api_response :post, 400, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: {candidateId: @candidate.id, startKind: "owned", sourceVehicleId: vehicle.id}
  end

  test "POST rejects a buy-back already spent" do
    pledge = create(:buyback_pledge, user: @user)
    @slot.update!(quantity: 2)
    @plan.acquisitions.create!(candidate: @candidate, start_kind: "buyback", buyback_pledge: pledge, start_model: @carrack)

    assert_api_response :post, 400, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id},
      body: {candidateId: @candidate.id, startKind: "buyback", buybackPledgeId: pledge.id, startModelId: @carrack.id}
  end

  test "PUT replaces the chain and sets a price override" do
    acquisition = @plan.acquisitions.new(candidate: @candidate, start_kind: "store", start_model: @cutlass)
    acquisition.upgrade_steps.build(source_kind: "store", origin_model: @cutlass, target_model: @carrack, position: 0)
    acquisition.save!

    body = {
      priceOverride: 90,
      steps: [
        {sourceKind: "store", toModelId: @constellation.id, priceOverride: 120},
        {sourceKind: "store", toModelId: @carrack.id}
      ]
    }

    assert_api_response :put, 200, api_path: "/hangar/plans/{hangarPlanId}/acquisitions/{id}",
      path_params: {hangarPlanId: @plan.id, id: acquisition.id}, body: do
      route = parsed_body.dig("slots", 0, "candidates", 0, "acquisitions", 0)
      assert_in_delta 90.0, route["price"]
      assert_equal [120.0, 350.0], route["steps"].pluck("price")
    end
  end

  test "PUT keeps the chain when the update leaves it alone" do
    acquisition = @plan.acquisitions.new(candidate: @candidate, start_kind: "store", start_model: @cutlass)
    acquisition.upgrade_steps.build(source_kind: "store", origin_model: @cutlass, target_model: @carrack, position: 0)
    acquisition.save!

    assert_api_response :put, 200, api_path: "/hangar/plans/{hangarPlanId}/acquisitions/{id}",
      path_params: {hangarPlanId: @plan.id, id: acquisition.id}, body: {priceOverride: 95} do
      assert_equal 1, parsed_body.dig("slots", 0, "candidates", 0, "acquisitions", 0, "steps").size
    end
  end

  test "PUT rolls back a chain that no longer ends on the slot's ship" do
    acquisition = @plan.acquisitions.create!(candidate: @candidate, start_kind: "store", start_model: @carrack)

    assert_api_response :put, 400, api_path: "/hangar/plans/{hangarPlanId}/acquisitions/{id}",
      path_params: {hangarPlanId: @plan.id, id: acquisition.id},
      body: {steps: [{sourceKind: "store", toModelId: @cutlass.id}]}

    assert_empty acquisition.reload.upgrade_steps
  end

  test "DELETE removes a route" do
    acquisition = @plan.acquisitions.create!(candidate: @candidate, start_kind: "store", start_model: @carrack)

    assert_api_response :delete, 200, api_path: "/hangar/plans/{hangarPlanId}/acquisitions/{id}",
      path_params: {hangarPlanId: @plan.id, id: acquisition.id} do
      assert_empty parsed_body.dig("slots", 0, "candidates", 0, "acquisitions")
    end
  end
end
