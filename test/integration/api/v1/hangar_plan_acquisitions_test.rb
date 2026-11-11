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
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
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

  test "POST saves a start on a slot with no ship" do
    slot = create(:hangar_plan_slot, hangar_plan: @plan)
    vehicle = create(:vehicle, user: @user, model: @cutlass)

    assert_api_response :post, 201, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: {slotId: slot.id, startKind: "owned", sourceVehicleId: vehicle.id} do
      start = parsed_body.dig("slots", 1, "starts", 0)
      assert_equal vehicle.id, start["sourceVehicleId"]
      assert_equal "Cutlass Black", start.dig("startModel", "name")
      assert_equal "open", parsed_body.dig("slots", 1, "state")
    end
  end

  test "POST saves a ship to buy on a slot with no ship, naming none" do
    slot = create(:hangar_plan_slot, hangar_plan: @plan)

    assert_api_response :post, 201, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: {slotId: slot.id, startKind: "store", startModelId: nil} do
      assert_nil parsed_body.dig("slots", 1, "starts", 0, "startModel")
    end
  end

  test "POST rejects a start on a slot that already has a ship" do
    assert_api_response :post, 400, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: {slotId: @slot.id, startKind: "store"}
  end

  test "POST rejects a start for neither a ship nor a slot" do
    assert_api_response :post, 400, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: {startKind: "store", startModelId: @carrack.id}
  end

  test "POST does not reach another user's slot" do
    other = create(:hangar_plan_slot, hangar_plan: create(:hangar_plan))

    assert_api_response :post, 404, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: {slotId: other.id, startKind: "store"}
  end

  test "PUT changes a start a slot holds, and moves it to a ship" do
    slot = create(:hangar_plan_slot, hangar_plan: @plan)
    start = @plan.acquisitions.create!(slot:, start_kind: "store")
    vehicle = create(:vehicle, user: @user, model: @cutlass)

    assert_api_response :put, 200, api_path: "/hangar/plans/{hangarPlanId}/acquisitions/{id}",
      path_params: {hangarPlanId: @plan.id, id: start.id}, body: {startKind: "owned", sourceVehicleId: vehicle.id}
    assert_equal slot, start.reload.slot

    target = create(:hangar_plan_slot, hangar_plan: @plan)
    candidate = create(:hangar_plan_candidate, slot: target, model: @constellation)

    assert_api_response :put, 200, api_path: "/hangar/plans/{hangarPlanId}/acquisitions/{id}",
      path_params: {hangarPlanId: @plan.id, id: start.id}, body: {candidateId: candidate.id}
    assert_nil start.reload.slot
    assert_equal candidate, start.candidate
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

  test "POST says which upgrade another route already uses" do
    ccu = create(:hangar_pledge_item, user: @user, kind: "ccu", name: "Upgrade - Constellation To Carrack")
    @slot.update!(quantity: 2)
    steps = [{sourceKind: "owned_ccu", hangarPledgeItemId: ccu.id, toModelId: @carrack.id}]
    2.times do |index|
      body = {candidateId: @candidate.id, startKind: "owned", sourceVehicleId: create(:vehicle, user: @user, model: @constellation).id, steps:}
      status = index.zero? ? 201 : 400

      assert_api_response :post, status, api_path: "/hangar/plans/{hangarPlanId}/acquisitions", path_params: {hangarPlanId: @plan.id}, body: do
        next if index.zero?

        messages = parsed_body["errors"].flat_map { |error| error["messages"].pluck("message") }
        assert_includes messages, "Hangar pledge item is already used in this plan"
        assert_not_includes messages, "Upgrade steps is invalid"
      end
    end
  end

  test "POST holds a start elsewhere until its route is planned" do
    assert_api_response :post, 201, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: {candidateId: @candidate.id, startKind: "store", startModelId: @cutlass.id} do
      route = parsed_body.dig("slots", 0, "candidates", 0, "acquisitions", 0)
      assert_equal false, route["routeComplete"]
      assert_equal @cutlass.id, route.dig("startModel", "id")
    end
  end

  test "POST rejects upgrades that do not end on the slot's ship" do
    assert_api_response :post, 400, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id},
      body: {candidateId: @candidate.id, startKind: "store", startModelId: @cutlass.id, steps: [{sourceKind: "store", toModelId: @constellation.id}]}
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

  test "POST starts a slot with another ship of a pledge the plan buys back, for free and once" do
    pledge = create(:buyback_pledge, user: @user, kind: "package", name: "Package - Duo",
      ship_names: ["Carrack", "Cutlass Black"])
    pledge_start = @plan.acquisitions.create!(candidate: @candidate, start_kind: "buyback", buyback_pledge: pledge, start_model: @carrack)
    cutlass_slot = create(:hangar_plan_slot, hangar_plan: @plan, quantity: 2)
    cutlass = create(:hangar_plan_candidate, slot: cutlass_slot, model: @cutlass)
    body = {candidateId: cutlass.id, startKind: "bundled", bundledWithId: pledge_start.id, startModelId: @cutlass.id}

    assert_api_response :post, 201, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: do
      start = parsed_body["slots"].flat_map { |slot| slot["candidates"] }.find { |entry| entry["id"] == cutlass.id }
        .dig("acquisitions", 0)

      assert_equal ["bundled", pledge_start.id, 0.0], start.values_at("startKind", "bundledWithId", "price")
      assert start["routeComplete"]
    end

    # The pledge holds one Cutlass, and no Constellation at all.
    assert_api_response :post, 400, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: do
      assert_includes parsed_body["errors"].flat_map { |error| error["messages"] }.pluck("code"), "taken"
    end
    assert_api_response :post, 400, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: body.merge(startModelId: @constellation.id) do
      assert_includes parsed_body["errors"].flat_map { |error| error["messages"] }.pluck("code"), "not_bundled"
    end
  end

  test "PUT to another pledge lets go of the ships the old one brought along" do
    pledge = create(:buyback_pledge, user: @user, kind: "package", name: "Package - Duo",
      ship_names: ["Carrack", "Cutlass Black"])
    pledge_start = @plan.acquisitions.create!(candidate: @candidate, start_kind: "buyback", buyback_pledge: pledge, start_model: @carrack)
    cutlass = create(:hangar_plan_candidate, slot: create(:hangar_plan_slot, hangar_plan: @plan), model: @cutlass)
    bundled = @plan.acquisitions.create!(candidate: cutlass, start_kind: "bundled", bundled_with: pledge_start, start_model: @cutlass)

    assert_api_response :put, 200, api_path: "/hangar/plans/{hangarPlanId}/acquisitions/{id}",
      path_params: {hangarPlanId: @plan.id, id: pledge_start.id},
      body: {startKind: "store", buybackPledgeId: nil, startModelId: @carrack.id}

    assert_not HangarPlanAcquisition.exists?(bundled.id)
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

  test "PUT moves a route's start to a ship of the hangar" do
    acquisition = @plan.acquisitions.create!(candidate: @candidate, start_kind: "store", start_model: @carrack)
    owned = create(:vehicle, user: @user, model: @carrack)

    assert_api_response :put, 200, api_path: "/hangar/plans/{hangarPlanId}/acquisitions/{id}",
      path_params: {hangarPlanId: @plan.id, id: acquisition.id},
      body: {startKind: "owned", sourceVehicleId: owned.id, startModelId: nil} do
      route = parsed_body.dig("slots", 0, "candidates", 0, "acquisitions", 0)
      assert_equal "owned", route["startKind"]
      assert_equal owned.id, route["sourceVehicleId"]
    end
  end

  test "PUT chains the steps from a new hangar ship without being told its model" do
    acquisition = @plan.acquisitions.create!(candidate: @candidate, start_kind: "owned", source_vehicle: create(:vehicle, user: @user, model: @carrack))
    vehicle = create(:vehicle, user: @user, model: @cutlass)

    assert_api_response :put, 200, api_path: "/hangar/plans/{hangarPlanId}/acquisitions/{id}",
      path_params: {hangarPlanId: @plan.id, id: acquisition.id},
      body: {sourceVehicleId: vehicle.id, steps: [{sourceKind: "store", toModelId: @carrack.id}]}

    assert_equal @cutlass, acquisition.reload.upgrade_steps.first.origin_model
  end

  test "PUT refuses a start another route already uses" do
    owned = create(:vehicle, user: @user, model: @carrack)
    @slot.update!(quantity: 2)
    @plan.acquisitions.create!(candidate: @candidate, start_kind: "owned", source_vehicle: owned)
    acquisition = @plan.acquisitions.create!(candidate: @candidate, start_kind: "store", start_model: @carrack)

    assert_api_response :put, 400, api_path: "/hangar/plans/{hangarPlanId}/acquisitions/{id}",
      path_params: {hangarPlanId: @plan.id, id: acquisition.id},
      body: {startKind: "owned", sourceVehicleId: owned.id, startModelId: nil}
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

  test "PUT moves a route to another ship of the plan" do
    vehicle = create(:vehicle, user: @user, model: @cutlass)
    acquisition = @plan.acquisitions.create!(candidate: @candidate, start_kind: "owned", source_vehicle: vehicle)
    other = create(:hangar_plan_candidate, slot: create(:hangar_plan_slot, hangar_plan: @plan), model: @constellation)

    assert_api_response :put, 200, api_path: "/hangar/plans/{hangarPlanId}/acquisitions/{id}",
      path_params: {hangarPlanId: @plan.id, id: acquisition.id}, body: {candidateId: other.id, steps: []}

    assert_equal other, acquisition.reload.candidate
    assert_equal vehicle, acquisition.source_vehicle
  end

  test "PUT does not move a route to another user's plan" do
    acquisition = @plan.acquisitions.create!(candidate: @candidate, start_kind: "store", start_model: @carrack)
    foreign = create(:hangar_plan_candidate, slot: create(:hangar_plan_slot, hangar_plan: create(:hangar_plan)), model: @cutlass)

    assert_api_response :put, 404, api_path: "/hangar/plans/{hangarPlanId}/acquisitions/{id}",
      path_params: {hangarPlanId: @plan.id, id: acquisition.id}, body: {candidateId: foreign.id}

    assert_equal @candidate, acquisition.reload.candidate
  end

  test "DELETE removes a route" do
    acquisition = @plan.acquisitions.create!(candidate: @candidate, start_kind: "store", start_model: @carrack)

    assert_api_response :delete, 200, api_path: "/hangar/plans/{hangarPlanId}/acquisitions/{id}",
      path_params: {hangarPlanId: @plan.id, id: acquisition.id} do
      assert_empty parsed_body.dig("slots", 0, "candidates", 0, "acquisitions")
    end
  end

  test "POST buys back the pledge of a ship the plan melts, at what melting it credits" do
    vehicle = create(:vehicle, user: @user, model: @constellation, rsi_pledge_id: "pledge-1", rsi_pledge_melt_value: 220)
    create(:hangar_plan_melt, hangar_plan: @plan, vehicle:)
    body = {
      candidateId: @candidate.id, startKind: "melted", sourceVehicleId: vehicle.id,
      steps: [{sourceKind: "store", toModelId: @carrack.id}]
    }

    assert_api_response :post, 201, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: do
      route = parsed_body.dig("slots", 0, "candidates", 0, "acquisitions", 0)
      assert_equal "melted", route["startKind"]
      assert_equal "Constellation", route.dig("startModel", "name")
      assert_in_delta 220.0, route["price"]
      assert route["usesBuybackToken"]
      assert route["routeComplete"]
      assert_equal false, route["sourceMissing"]
    end
  end

  test "POST buys back a pledge by any ship of it the plan melts, once" do
    melted = create(:vehicle, user: @user, model: @constellation, rsi_pledge_id: "pledge-1", rsi_pledge_melt_value: 300)
    sibling = create(:vehicle, user: @user, model: @cutlass, rsi_pledge_id: "pledge-1")
    create(:hangar_plan_melt, hangar_plan: @plan, vehicle: melted)
    @slot.update!(quantity: 2)

    assert_api_response :post, 201, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: {candidateId: @candidate.id, startKind: "melted", sourceVehicleId: sibling.id} do
      assert_in_delta 300.0, parsed_body.dig("slots", 0, "candidates", 0, "acquisitions", 0, "price")
    end

    assert_api_response :post, 400, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: {candidateId: @candidate.id, startKind: "melted", sourceVehicleId: melted.id} do
      messages = parsed_body["errors"].flat_map { |error| error["messages"].pluck("message") }
      assert_includes messages, "Source vehicle is already used in this plan"
    end
  end

  test "POST rejects buying back a ship the plan does not melt" do
    vehicle = create(:vehicle, user: @user, model: @constellation)

    assert_api_response :post, 400, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: {candidateId: @candidate.id, startKind: "melted", sourceVehicleId: vehicle.id} do
      messages = parsed_body["errors"].flat_map { |error| error["messages"].pluck("message") }
      assert_includes messages, "Source vehicle is not melted in this plan"
    end
  end

  test "taking a melt back takes the routes that buy its pledge back with it" do
    melted = create(:vehicle, user: @user, model: @constellation, rsi_pledge_id: "pledge-1")
    sibling = create(:vehicle, user: @user, model: @cutlass, rsi_pledge_id: "pledge-1")
    melt = create(:hangar_plan_melt, hangar_plan: @plan, vehicle: melted)
    @slot.update!(quantity: 2)
    route = @plan.acquisitions.create!(candidate: @candidate, start_kind: "melted", source_vehicle: sibling)
    kept = @plan.acquisitions.create!(candidate: @candidate, start_kind: "store", start_model: @carrack)

    melt.destroy!

    assert_not HangarPlanAcquisition.exists?(route.id)
    assert HangarPlanAcquisition.exists?(kept.id)
  end

  test "POST buys back an upgraded pledge as the ship it was first bought as" do
    starlancer = create(:model, name: "Starlancer MAX", pledge_price: 250)
    ironclad = create(:model, name: "Ironclad Assault", pledge_price: 650)
    @candidate.update!(model: starlancer)
    vehicle = create(:vehicle, user: @user, model: ironclad, rsi_pledge_id: "pledge-1", rsi_pledge_melt_value: 465,
      rsi_pledge_name: "Standalone Ships - Starlancer MAX plus Pacific Paints - CitizenCon 2954")
    create(:hangar_plan_melt, hangar_plan: @plan, vehicle:)

    assert_api_response :post, 201, api_path: "/hangar/plans/{hangarPlanId}/acquisitions",
      path_params: {hangarPlanId: @plan.id}, body: {candidateId: @candidate.id, startKind: "melted", sourceVehicleId: vehicle.id} do
      route = parsed_body.dig("slots", 0, "candidates", 0, "acquisitions", 0)
      assert_equal "Starlancer MAX", route.dig("startModel", "name")
      assert_in_delta 250.0, route["price"]
      assert route["routeComplete"]
    end
  end
end
