# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarPlanReportsTest < ActionDispatch::IntegrationTest
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

  ID = {name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true}.freeze

  api_path "/hangar/plans/{id}/summary" do
    parameter(**ID)

    get("Hangar Plan Summary") do
      operationId "hangarPlanSummary"
      tags "HangarPlans"
      produces "application/json"
      security READ_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Hangar::Plans::HangarPlanSummary }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/hangar/plans/{id}/comparison" do
    parameter(**ID)

    get("Hangar Plan Comparison with the Hangar") do
      operationId "hangarPlanComparison"
      tags "HangarPlans"
      produces "application/json"
      security READ_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Hangar::Plans::HangarPlanComparison }
    end
  end

  api_path "/hangar/plans/{id}/compare/{otherId}" do
    parameter(**ID)
    parameter name: "otherId", in: :path, schema: {type: :string, format: :uuid}, required: true

    get("Compare two Hangar Plans") do
      operationId "compareHangarPlans"
      tags "HangarPlans"
      produces "application/json"
      security READ_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Hangar::Plans::HangarPlanCompare }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/hangar/plans/{id}/drift" do
    parameter(**ID)

    get("Hangar Plan Drift") do
      operationId "hangarPlanDrift"
      tags "HangarPlans"
      produces "application/json"
      security READ_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Hangar::Plans::HangarPlanDrift }
    end
  end

  api_path "/hangar/plans/{id}/rebase" do
    parameter(**ID)

    put("Rebase Hangar Plan on the Hangar") do
      operationId "rebaseHangarPlan"
      tags "HangarPlans"
      produces "application/json"
      security WRITE_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Hangar::Plans::HangarPlan }
    end
  end

  api_path "/hangar/plans/{id}/add-to-wishlist" do
    parameter(**ID)

    put("Add Hangar Plan Purchases to the Wishlist") do
      operationId "addHangarPlanToWishlist"
      tags "HangarPlans"
      produces "application/json"
      security WRITE_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Hangar::Plans::HangarPlanWishlistResult }
    end
  end

  api_path "/hangar/plans/{id}/resources" do
    parameter(**ID)

    get("Hangar Plan Resources") do
      operationId "hangarPlanResources"
      tags "HangarPlans"
      produces "application/json"
      security READ_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Hangar::Plans::HangarPlanResources }
    end
  end

  setup do
    Flipper.enable(:hangar_planner)
    @user = create(:user)
    @cutlass = create(:model, name: "Cutlass Black", pledge_price: 100, on_sale: true)
    @carrack = create(:model, name: "Carrack", pledge_price: 600, on_sale: true)
    @owned = create(:vehicle, user: @user, model: @cutlass)
    @plan = @user.hangar_plans.new(name: "Explorer")
    HangarPlans::Builder.new(@plan, source: "hangar").run
    @carrack_slot = @plan.slots.create!(label: "Explorer", quantity: 2)
    @carrack_candidate = @carrack_slot.candidates.create!(model: @carrack)
    @plan.acquisitions.create!(candidate: @carrack_candidate, start_kind: "store", start_model: @carrack)
    sign_in @user
  end

  test "GET summary totals the decided routes and counts the gap" do
    assert_api_response :get, 200, api_path: "/hangar/plans/{id}/summary", path_params: {id: @plan.id} do
      assert_in_delta 600.0, parsed_body.dig("totals", "spendMin")
      assert_equal 1, parsed_body.dig("totals", "unresolvedCount")
      assert_not parsed_body.dig("totals", "complete")
    end
  end

  test "GET summary returns 404 for another user's plan" do
    sign_in create(:user)

    assert_api_response :get, 404, api_path: "/hangar/plans/{id}/summary", path_params: {id: @plan.id}
  end

  test "GET comparison shows each ship and the metrics side by side" do
    assert_api_response :get, 200, api_path: "/hangar/plans/{id}/comparison", path_params: {id: @plan.id} do
      assert_equal [["kept", @owned.id]], parsed_body["vehicles"].map { |entry| [entry["status"], entry["vehicleId"]] }
      assert_equal({"Carrack" => "added", "Cutlass Black" => "unchanged"},
        parsed_body["models"].to_h { |diff| [diff.dig("model", "name"), diff["change"]] })
      assert_equal [1, 3], [parsed_body.dig("metrics", "live", "total"), parsed_body.dig("metrics", "plan", "total")]
      assert_equal [1], parsed_body["gaps"].pluck("count")
    end
  end

  test "GET compare sets two plans side by side" do
    other = create(:hangar_plan, user: @user, name: "Lean")

    assert_api_response :get, 200, api_path: "/hangar/plans/{id}/compare/{otherId}", path_params: {id: @plan.id, otherId: other.id} do
      assert_equal "Lean", parsed_body["otherPlanName"]
      assert_equal %w[removed removed], parsed_body["models"].pluck("change")
      assert_in_delta 600.0, parsed_body.dig("totals", "left", "spendMin")
    end
  end

  test "GET compare returns 404 for another user's plan" do
    assert_api_response :get, 404, api_path: "/hangar/plans/{id}/compare/{otherId}", path_params: {id: @plan.id, otherId: create(:hangar_plan).id}
  end

  test "GET drift lists what changed since the plan was based" do
    @owned.destroy!
    @carrack.update_columns(pledge_price: 650)

    assert_api_response :get, 200, api_path: "/hangar/plans/{id}/drift", path_params: {id: @plan.id} do
      assert parsed_body["drifted"]
      assert_equal ["acquisition"], parsed_body["missingSources"].pluck("kind")
      assert_equal [600.0, 650.0], [parsed_body["previousTotal"], parsed_body["currentTotal"]]
    end
  end

  test "PUT rebase adds ships bought since" do
    travel 1.minute do
      create(:vehicle, user: @user, model: @carrack)

      assert_api_response :put, 200, api_path: "/hangar/plans/{id}/rebase", path_params: {id: @plan.id} do
        assert_equal 3, parsed_body["slots"].size
      end
    end
  end

  test "PUT add-to-wishlist wishes for every ship still to obtain" do
    assert_difference -> { @user.vehicles.wanted.where(model: @carrack).count }, 2 do
      assert_api_response :put, 200, api_path: "/hangar/plans/{id}/add-to-wishlist", path_params: {id: @plan.id} do
        assert_equal 2, parsed_body["added"]
      end
    end
  end

  test "PUT add-to-wishlist a second time adds nothing" do
    HangarPlans::WishlistApply.new(@plan).run

    assert_no_difference -> { @user.vehicles.wanted.count } do
      assert_api_response :put, 200, api_path: "/hangar/plans/{id}/add-to-wishlist", path_params: {id: @plan.id} do
        assert_equal 0, parsed_body["added"]
      end
    end
  end

  test "GET resources lists what the plan can spend, and what it already spends" do
    create(:hangar_pledge_item, user: @user, kind: "ccu", name: "Upgrade - Cutlass Black To Carrack")
    create(:buyback_pledge, user: @user, name: "Standalone Ship - Carrack")

    assert_api_response :get, 200, api_path: "/hangar/plans/{id}/resources", path_params: {id: @plan.id} do
      assert_equal [[@owned.id, "acquisition"]], parsed_body["vehicles"].map { |entry| [entry["id"], entry["usedBy"]] }
      assert_equal "Carrack", parsed_body.dig("upgrades", 0, "toModel", "name")
      assert_equal [false], parsed_body["buybacks"].pluck("used")
    end
  end
end
