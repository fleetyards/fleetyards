# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarPlanShareTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/plans/{id}/share" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    put("Share Hangar Plan") do
      operationId "shareHangarPlan"
      tags "HangarPlans"
      produces "application/json"
      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") { schema ::V1::Schemas::Hangar::Plans::HangarPlan }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    delete("Unshare Hangar Plan") do
      operationId "unshareHangarPlan"
      tags "HangarPlans"
      produces "application/json"
      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") { schema ::V1::Schemas::Hangar::Plans::HangarPlan }
    end
  end

  api_path "/public/hangar-plans/{token}" do
    parameter name: "token", in: :path, schema: {type: :string}, required: true

    get("Shared Hangar Plan") do
      operationId "publicHangarPlan"
      tags "HangarPlansPublic"
      produces "application/json"

      response(200, "successful") { schema ::V1::Schemas::Hangar::Plans::HangarPlan }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/public/hangar-plans/{token}/summary" do
    parameter name: "token", in: :path, schema: {type: :string}, required: true

    get("Shared Hangar Plan Summary") do
      operationId "publicHangarPlanSummary"
      tags "HangarPlansPublic"
      produces "application/json"

      response(200, "successful") { schema ::V1::Schemas::Hangar::Plans::HangarPlanSummary }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    Flipper.enable(:hangar_planner)
    @user = create(:user)
    @plan = create(:hangar_plan, user: @user, name: "Showcase")
  end

  test "PUT share creates a link, and sharing again keeps it" do
    sign_in @user

    assert_api_response :put, 200, api_path: "/hangar/plans/{id}/share", path_params: {id: @plan.id} do
      assert parsed_body["shared"]
      assert_predicate parsed_body["shareToken"], :present?
    end

    token = @plan.reload.share_token
    assert_api_response :put, 200, api_path: "/hangar/plans/{id}/share", path_params: {id: @plan.id}
    assert_equal token, @plan.reload.share_token
  end

  test "PUT share returns 404 for another user's plan" do
    sign_in create(:user)

    assert_api_response :put, 404, api_path: "/hangar/plans/{id}/share", path_params: {id: @plan.id}
  end

  test "DELETE share revokes the link" do
    @plan.share!
    token = @plan.share_token
    sign_in @user

    assert_api_response :delete, 200, api_path: "/hangar/plans/{id}/share", path_params: {id: @plan.id} do
      assert_not parsed_body["shared"]
    end

    assert_api_response :get, 404, api_path: "/public/hangar-plans/{token}", path_params: {token:}
  end

  test "GET a shared plan by its link, signed out and without the owner's hangar" do
    model = create(:model)
    candidate = create(:hangar_plan_candidate, slot: create(:hangar_plan_slot, hangar_plan: @plan), model:)
    @plan.acquisitions.create!(candidate:, start_kind: "owned", source_vehicle: create(:vehicle, user: @user, model:))
    create(:hangar_plan_melt, hangar_plan: @plan, vehicle: create(:vehicle, user: @user))
    @user.update_column(:rsi_buyback_tokens, 3)
    @plan.share!
    @user.vehicles.destroy_all

    assert_api_response :get, 200, api_path: "/public/hangar-plans/{token}", path_params: {token: @plan.share_token} do
      assert_equal "Showcase", parsed_body["name"]
      assert_not parsed_body.key?("shareToken")
      candidate = parsed_body.dig("slots", 0, "candidates", 0)
      assert_not candidate.key?("ownedCount")
      assert_not candidate.dig("acquisitions", 0).key?("sourceVehicleId")
      assert_not parsed_body.dig("melts", 0).key?("vehicleId")
      assert_nil parsed_body["syncedBuybackTokens"]
      assert_not candidate.dig("acquisitions", 0, "sourceMissing")
      assert_not parsed_body.dig("melts", 0, "vehicleMissing")
    end
  end

  test "GET a shared plan's summary" do
    @plan.share!

    assert_api_response :get, 200, api_path: "/public/hangar-plans/{token}/summary", path_params: {token: @plan.share_token}
  end

  test "GET an unknown link is not found" do
    assert_api_response :get, 404, api_path: "/public/hangar-plans/{token}", path_params: {token: "nope"}
  end

  test "GET a shared plan is not found while its owner has the feature off" do
    @plan.share!
    Flipper.disable(:hangar_planner)

    assert_api_response :get, 404, api_path: "/public/hangar-plans/{token}", path_params: {token: @plan.share_token}
  end
end
