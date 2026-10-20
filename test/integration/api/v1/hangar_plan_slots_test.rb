# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarPlanSlotsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  SECURITY = [
    {SessionCookie: []},
    {Oauth2: ["hangar", "hangar:write"]},
    {OpenId: ["hangar", "hangar:write"]}
  ].freeze

  PLAN = ::V1::Schemas::Hangar::Plans::HangarPlan

  api_path "/hangar/plans/{hangarPlanId}/slots" do
    parameter name: "hangarPlanId", in: :path, schema: {type: :string, format: :uuid}, required: true

    post("Create Hangar Plan Slot") do
      operationId "createHangarPlanSlot"
      tags "HangarPlans"
      consumes "application/json"
      produces "application/json"
      security SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarPlanSlotCreateInput

      response(201, "successful") { schema PLAN }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/hangar/plans/{hangarPlanId}/slots/sort" do
    parameter name: "hangarPlanId", in: :path, schema: {type: :string, format: :uuid}, required: true

    put("Sort Hangar Plan Slots") do
      operationId "sortHangarPlanSlots"
      tags "HangarPlans"
      consumes "application/json"
      produces "application/json"
      security SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarPlanSlotSortInput

      response(200, "successful") { schema PLAN }
    end
  end

  api_path "/hangar/plans/{hangarPlanId}/slots/{id}" do
    parameter name: "hangarPlanId", in: :path, schema: {type: :string, format: :uuid}, required: true
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    put("Update Hangar Plan Slot") do
      operationId "updateHangarPlanSlot"
      tags "HangarPlans"
      consumes "application/json"
      produces "application/json"
      security SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarPlanSlotUpdateInput

      response(200, "successful") { schema PLAN }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
    end

    delete("Destroy Hangar Plan Slot") do
      operationId "destroyHangarPlanSlot"
      tags "HangarPlans"
      produces "application/json"
      security SECURITY

      response(200, "successful") { schema PLAN }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/hangar/plans/{hangarPlanId}/slots/{id}/choose" do
    parameter name: "hangarPlanId", in: :path, schema: {type: :string, format: :uuid}, required: true
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    put("Choose Hangar Plan Slot Candidate") do
      operationId "chooseHangarPlanSlotCandidate"
      tags "HangarPlans"
      consumes "application/json"
      produces "application/json"
      security SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarPlanSlotChooseInput

      response(200, "successful") { schema PLAN }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    Flipper.enable(:hangar_planner)
    @user = create(:user)
    @plan = create(:hangar_plan, user: @user)
    @slot = create(:hangar_plan_slot, hangar_plan: @plan, label: "Hauler")
    sign_in @user
  end

  test "POST creates an open slot" do
    assert_api_response :post, 201, api_path: "/hangar/plans/{hangarPlanId}/slots",
      path_params: {hangarPlanId: @plan.id}, body: {label: "Escort", quantity: 3} do
      slot = parsed_body["slots"].find { |entry| entry["label"] == "Escort" }
      assert_equal [3, "open"], [slot["quantity"], slot["state"]]
    end
  end

  test "POST creates a slot with a description and filters" do
    body = {
      label: "Explorer", description: "Long trips, room for a snub",
      filters: {classificationIn: ["exploration"], pledgePriceLteq: 700, onSaleEq: true}
    }

    assert_api_response :post, 201, api_path: "/hangar/plans/{hangarPlanId}/slots",
      path_params: {hangarPlanId: @plan.id}, body: do
      slot = parsed_body["slots"].find { |entry| entry["label"] == "Explorer" }
      assert_equal "Long trips, room for a snub", slot["description"]
      assert_equal({"classificationIn" => ["exploration"], "pledgePriceLteq" => 700.0, "onSaleEq" => true}, slot["filters"])
    end
  end

  test "POST rejects a slot without a label" do
    assert_api_response :post, 400, api_path: "/hangar/plans/{hangarPlanId}/slots",
      path_params: {hangarPlanId: @plan.id}, body: {label: ""}
  end

  test "POST returns 404 for another user's plan" do
    other = create(:hangar_plan)

    assert_api_response :post, 404, api_path: "/hangar/plans/{hangarPlanId}/slots",
      path_params: {hangarPlanId: other.id}, body: {label: "Escort"}
  end

  test "PUT updates a slot" do
    assert_api_response :put, 200, api_path: "/hangar/plans/{hangarPlanId}/slots/{id}",
      path_params: {hangarPlanId: @plan.id, id: @slot.id}, body: {quantity: 2} do
      assert_equal 2, parsed_body.dig("slots", 0, "quantity")
    end
  end

  test "PUT with an empty filter set clears the filters" do
    @slot.update!(filters: {size_in: ["small"]})

    assert_api_response :put, 200, api_path: "/hangar/plans/{hangarPlanId}/slots/{id}",
      path_params: {hangarPlanId: @plan.id, id: @slot.id}, body: {filters: {}} do
      assert_empty parsed_body.dig("slots", 0, "filters")
    end
  end

  test "PUT marks a candidate outside the slot's filters" do
    create(:hangar_plan_candidate, slot: @slot, model: create(:model, size: "large"))

    assert_api_response :put, 200, api_path: "/hangar/plans/{hangarPlanId}/slots/{id}",
      path_params: {hangarPlanId: @plan.id, id: @slot.id}, body: {filters: {sizeIn: ["small"]}} do
      assert_not parsed_body.dig("slots", 0, "candidates", 0, "matchesFilters")
    end
  end

  test "PUT rejects a quantity of zero" do
    assert_api_response :put, 400, api_path: "/hangar/plans/{hangarPlanId}/slots/{id}",
      path_params: {hangarPlanId: @plan.id, id: @slot.id}, body: {quantity: 0}
  end

  test "DELETE removes a slot" do
    assert_api_response :delete, 200, api_path: "/hangar/plans/{hangarPlanId}/slots/{id}",
      path_params: {hangarPlanId: @plan.id, id: @slot.id} do
      assert_empty parsed_body["slots"]
    end
  end

  test "PUT sort reorders the slots" do
    second = create(:hangar_plan_slot, hangar_plan: @plan, label: "Miner")

    assert_api_response :put, 200, api_path: "/hangar/plans/{hangarPlanId}/slots/sort",
      path_params: {hangarPlanId: @plan.id}, body: {sorting: [second.id, @slot.id]} do
      assert_equal ["Miner", "Hauler"], parsed_body["slots"].pluck("label")
    end
  end

  test "PUT choose keeps one candidate and drops the rest" do
    keep = create(:hangar_plan_candidate, slot: @slot)
    create(:hangar_plan_candidate, slot: @slot)

    assert_api_response :put, 200, api_path: "/hangar/plans/{hangarPlanId}/slots/{id}/choose",
      path_params: {hangarPlanId: @plan.id, id: @slot.id}, body: {candidateId: keep.id} do
      slot = parsed_body["slots"].first
      assert_equal "decided", slot["state"]
      assert_equal [keep.id], slot["candidates"].pluck("id")
    end
  end
end
