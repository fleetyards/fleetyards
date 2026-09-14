# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetContractItemsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  COLLECTION_PATH = "/fleets/{fleetSlug}/contracts/{fleetContractSlug}/items"
  MEMBER_PATH = "/fleets/{fleetSlug}/contracts/{fleetContractSlug}/items/{id}"

  api_path COLLECTION_PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "fleetContractSlug", in: :path, schema: {type: :string}

    post("Create Fleet Contract Item") do
      operationId "createFleetContractItem"
      tags "Contracts"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetContractItemInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractItem
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path MEMBER_PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "fleetContractSlug", in: :path, schema: {type: :string}
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    patch("Update Fleet Contract Item") do
      operationId "updateFleetContractItem"
      tags "Contracts"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetContractItemInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractItem
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end
    end

    delete("Delete Fleet Contract Item") do
      operationId "destroyFleetContractItem"
      tags "Contracts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful")

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_contracts")

    @officer = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@officer], members: [@member])
    @depot = create(:fleet_inventory, fleet: @fleet)
    @contract = create(:fleet_contract, fleet: @fleet, destination_fleet_inventory: @depot)
  end

  test "POST adds a line" do
    sign_in @officer

    assert_api_response :post, 201,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug},
      body: {name: "Titanium", category: "commodity", unit: "scu", quantity: "800"} do
      assert_equal "Titanium", parsed_body["name"]
      assert_equal 1, parsed_body["position"]
    end
  end

  # The contract records *which* commodity or item it wants, not just a name --
  # picked out of the same catalogues the inventory ledger references.
  test "POST stores the commodity the contract asks for" do
    commodity = create(:commodity)
    sign_in @officer

    assert_api_response :post, 201,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug},
      body: {name: commodity.name, category: "commodity", unit: "scu", quantity: "800",
             itemType: "Commodity", itemId: commodity.id} do
      assert_equal "Commodity", parsed_body["item"]["type"]
      assert_equal commodity.id, parsed_body["item"]["id"]
      assert_equal commodity.name, parsed_body["item"]["name"]
    end

    assert_equal commodity, @contract.fleet_contract_items.sole.item
  end

  test "POST stores a component, and the grade asked for beside it" do
    component = create(:component)
    sign_in @officer

    assert_api_response :post, 201,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug},
      body: {name: component.name, category: "component", unit: "units", quantity: "12",
             quality: 750, itemType: "Component", itemId: component.id} do
      assert_equal "Component", parsed_body["item"]["type"]
      assert_equal 750, parsed_body["quality"]
      assert_equal "at_least", parsed_body["qualityMatch"]
    end
  end

  test "POST records a grade that has to be matched exactly" do
    sign_in @officer

    assert_api_response :post, 201,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug},
      body: {name: "Tuned Cooler", category: "component", unit: "units", quantity: "4",
             quality: 500, qualityMatch: "exact"} do
      assert_equal "exact", parsed_body["qualityMatch"]
      assert_equal 500, parsed_body["quality"]
    end
  end

  # Asking for something no catalogue carries stays allowed; it just is not a
  # reference. The ledger is matched by name, category and unit either way.
  test "POST without a reference stores the line all the same" do
    sign_in @officer

    assert_api_response :post, 201,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug},
      body: {name: "Salvaged hull plating", category: "other", unit: "scu", quantity: "40"} do
      assert_nil parsed_body["item"]
    end
  end

  test "POST refuses a reference to something that is not there" do
    sign_in @officer

    assert_api_response :post, 400,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug},
      body: {name: "Titanium", category: "commodity", unit: "scu", quantity: "800",
             itemType: "Commodity", itemId: SecureRandom.uuid}
  end

  test "POST adds several different goods to one contract" do
    sign_in @officer

    [["Titanium", "commodity", "scu"],
      ["Quantanium", "commodity", "scu"],
      ["Power Plant", "component", "units"]].each do |name, category, unit|
      assert_api_response :post, 201,
        api_path: COLLECTION_PATH,
        path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug},
        body: {name: name, category: category, unit: unit, quantity: "10"}
    end

    assert_equal 3, @contract.fleet_contract_items.count
  end

  # The same goods twice would match the same deposits, so one delivery would
  # satisfy both lines -- but the refusal has to say that, not "name taken".
  test "POST refuses the same goods twice, and says why" do
    sign_in @officer

    2.times do |index|
      assert_api_response :post, (index.zero? ? 201 : 400),
        api_path: COLLECTION_PATH,
        path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug},
        body: {name: "Titanium", category: "commodity", unit: "scu", quantity: "10"} do
        next if index.zero?

        message = parsed_body["errors"].first["messages"].first["message"]

        assert_match(/already on this contract/, message)
      end
    end
  end

  test "POST refuses a unit the category does not use" do
    sign_in @officer

    assert_api_response :post, 400,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug},
      body: {name: "Power Plant", category: "component", unit: "scu", quantity: "4"}
  end

  test "POST refuses a quantity of nothing" do
    sign_in @officer

    assert_api_response :post, 400,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug},
      body: {name: "Titanium", category: "commodity", unit: "scu", quantity: "0"}
  end

  test "a member without the update privilege cannot add a line" do
    sign_in @member

    assert_api_response :post, 403,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug},
      body: {name: "Titanium", category: "commodity", unit: "scu", quantity: "800"}
  end

  test "PATCH changes a line" do
    item = create(:fleet_contract_item, fleet_contract: @contract, quantity: 100)
    sign_in @officer

    assert_api_response :patch, 200,
      api_path: MEMBER_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug, id: item.id},
      body: {name: item.name, category: item.category, unit: item.unit, quantity: "250"} do
      assert_equal "250.0", parsed_body["quantity"]
    end
  end

  test "DELETE removes a line" do
    item = create(:fleet_contract_item, fleet_contract: @contract)
    sign_in @officer

    assert_api_response :delete, 204,
      api_path: MEMBER_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug, id: item.id}
  end

  test "a line in another fleet's contract is a 404" do
    other = create(:fleet_contract_item)
    sign_in @officer

    assert_api_response :delete, 404,
      api_path: MEMBER_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug, id: other.id}
  end

  test "POST needs a signed-in user" do
    assert_api_response :post, 401,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug},
      body: {name: "Titanium", category: "commodity", unit: "scu", quantity: "800"}
  end
end
