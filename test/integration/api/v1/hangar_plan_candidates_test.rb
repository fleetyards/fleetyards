# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarPlanCandidatesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  SECURITY = [
    {SessionCookie: []},
    {Oauth2: ["hangar", "hangar:write"]},
    {OpenId: ["hangar", "hangar:write"]}
  ].freeze

  PLAN = ::V1::Schemas::Hangar::Plans::HangarPlan

  api_path "/hangar/plans/{hangarPlanId}/candidates" do
    parameter name: "hangarPlanId", in: :path, schema: {type: :string, format: :uuid}, required: true

    post("Create Hangar Plan Candidate") do
      operationId "createHangarPlanCandidate"
      tags "HangarPlans"
      consumes "application/json"
      produces "application/json"
      security SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarPlanCandidateCreateInput

      response(201, "successful") { schema PLAN }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/hangar/plans/{hangarPlanId}/candidates/{id}" do
    parameter name: "hangarPlanId", in: :path, schema: {type: :string, format: :uuid}, required: true
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    put("Update Hangar Plan Candidate") do
      operationId "updateHangarPlanCandidate"
      tags "HangarPlans"
      consumes "application/json"
      produces "application/json"
      security SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarPlanCandidateUpdateInput

      response(200, "successful") { schema PLAN }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
    end

    delete("Destroy Hangar Plan Candidate") do
      operationId "destroyHangarPlanCandidate"
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
    @slot = create(:hangar_plan_slot, hangar_plan: @plan)
    @gladius = create(:model, name: "Gladius")
    @arrow = create(:model, name: "Arrow")
    sign_in @user
  end

  test "POST adds a candidate, and a second makes the slot undecided" do
    create(:hangar_plan_candidate, slot: @slot, model: @arrow)

    assert_api_response :post, 201, api_path: "/hangar/plans/{hangarPlanId}/candidates",
      path_params: {hangarPlanId: @plan.id}, body: {slotId: @slot.id, modelId: @gladius.id} do
      slot = parsed_body["slots"].first
      assert_equal "undecided", slot["state"]
      assert_equal %w[Arrow Gladius], slot["candidates"].map { |candidate| candidate.dig("model", "name") }
    end
  end

  test "POST rejects the same ship twice in a slot" do
    create(:hangar_plan_candidate, slot: @slot, model: @gladius)

    assert_api_response :post, 400, api_path: "/hangar/plans/{hangarPlanId}/candidates",
      path_params: {hangarPlanId: @plan.id}, body: {slotId: @slot.id, modelId: @gladius.id}
  end

  test "POST returns 404 for a slot of another user's plan" do
    other = create(:hangar_plan_slot)

    assert_api_response :post, 404, api_path: "/hangar/plans/{hangarPlanId}/candidates",
      path_params: {hangarPlanId: @plan.id}, body: {slotId: other.id, modelId: @gladius.id}
  end

  test "PUT sets the paint" do
    candidate = create(:hangar_plan_candidate, slot: @slot, model: @gladius)
    paint = create(:model_paint, model: @gladius, name: "Valiant")

    assert_api_response :put, 200, api_path: "/hangar/plans/{hangarPlanId}/candidates/{id}",
      path_params: {hangarPlanId: @plan.id, id: candidate.id}, body: {modelPaintId: paint.id} do
      assert_equal "Valiant", parsed_body.dig("slots", 0, "candidates", 0, "paintName")
    end
  end

  test "PUT rejects a paint of another ship" do
    candidate = create(:hangar_plan_candidate, slot: @slot, model: @gladius)

    assert_api_response :put, 400, api_path: "/hangar/plans/{hangarPlanId}/candidates/{id}",
      path_params: {hangarPlanId: @plan.id, id: candidate.id}, body: {modelPaintId: create(:model_paint, model: @arrow).id}
  end

  test "DELETE removes a candidate" do
    candidate = create(:hangar_plan_candidate, slot: @slot, model: @gladius)

    assert_api_response :delete, 200, api_path: "/hangar/plans/{hangarPlanId}/candidates/{id}",
      path_params: {hangarPlanId: @plan.id, id: candidate.id} do
      assert_equal "open", parsed_body.dig("slots", 0, "state")
    end
  end
end
