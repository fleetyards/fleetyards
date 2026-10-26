# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetShoppingListsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  READ = [
    {SessionCookie: []},
    {Oauth2: ["fleet", "fleet:read"]},
    {OpenId: ["fleet", "fleet:read"]}
  ].freeze

  WRITE = [
    {SessionCookie: []},
    {Oauth2: ["fleet", "fleet:write", "hangar", "hangar:read"]},
    {OpenId: ["fleet", "fleet:write", "hangar", "hangar:read"]}
  ].freeze

  api_path "/fleets/{fleetSlug}/shopping-lists" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Shopping Lists") do
      operationId "fleetShoppingLists"
      tags "FleetShoppingLists"
      produces "application/json"
      security READ

      response(200, "successful") { schema ::V1::Schemas::Fleets::ShoppingLists::FleetShoppingListsList }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
    end

    post("Create Fleet Shopping List") do
      operationId "createFleetShoppingList"
      tags "FleetShoppingLists"
      consumes "application/json"
      produces "application/json"
      security WRITE

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetShoppingListCreateInput

      response(201, "successful") { schema ::V1::Schemas::Fleets::ShoppingLists::FleetShoppingList }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/fleets/{fleetSlug}/shopping-lists/{id}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    get("Fleet Shopping List") do
      operationId "fleetShoppingList"
      tags "FleetShoppingLists"
      produces "application/json"
      security READ

      response(200, "successful") { schema ::V1::Schemas::Fleets::ShoppingLists::FleetShoppingListDetail }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    put("Update Fleet Shopping List") do
      operationId "updateFleetShoppingList"
      tags "FleetShoppingLists"
      consumes "application/json"
      produces "application/json"
      security WRITE

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetShoppingListUpdateInput

      response(200, "successful") { schema ::V1::Schemas::Fleets::ShoppingLists::FleetShoppingList }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    delete("Destroy Fleet Shopping List") do
      operationId "destroyFleetShoppingList"
      tags "FleetShoppingLists"
      produces "application/json"
      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") { schema ::V1::Schemas::SuccessResponse }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/fleets/{fleetSlug}/shopping-lists/{id}/copy" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    post("Copy Fleet Shopping List") do
      operationId "copyFleetShoppingList"
      tags "FleetShoppingLists"
      consumes "application/json"
      produces "application/json"
      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read", "hangar", "hangar:write"]},
        {OpenId: ["fleet", "fleet:read", "hangar", "hangar:write"]}
      ]

      request_body required: false, schema: ::V1::Schemas::Inputs::FleetShoppingListCopyInput

      response(200, "successful") { schema ::V1::Schemas::Carts::Cart }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    Flipper.enable(:shopping_cart)
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])

    @armor = create(:equipment)
    @helmet = create(:equipment)

    @kit = create(:fleet_shopping_list, fleet: @fleet, name: "Standard kit")
    create(:fleet_shopping_list_item, fleet_shopping_list: @kit, item: @armor, quantity: 1)
    create(:fleet_shopping_list_item, fleet_shopping_list: @kit, item: @helmet, quantity: 2)

    @squadron = create(:fleet_squadron, fleet: @fleet, name: "Rescue")
    @rescue_kit = create(:fleet_shopping_list, fleet: @fleet, name: "Rescue kit",
      visibility: :squadron_only, fleet_squadrons: [@squadron])
    @officers_kit = create(:fleet_shopping_list, fleet: @fleet, name: "Officer dress", visibility: :officers_only)
  end

  test "GET lists what a member may see, with line and item counts" do
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal [["Standard kit", 2, 3]], parsed_body.map { |list| list.values_at("name", "linesCount", "itemsCount") }
    end
  end

  test "GET lists squadron-only lists to the squadron's members" do
    membership = @fleet.fleet_memberships.find_by!(user: @member)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: membership)
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal ["Rescue kit", "Standard kit"], parsed_body.pluck("name")
    end
  end

  test "GET lists every list to an admin" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal ["Officer dress", "Rescue kit", "Standard kit"], parsed_body.pluck("name")
    end
  end

  test "GET is forbidden while the feature is off" do
    Flipper.disable(:shopping_cart)
    sign_in @member

    assert_api_response :get, 403, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET answers 401 when signed out" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET a list prices its lines" do
    sign_in @member

    assert_api_response :get, 200, api_path: "/fleets/{fleetSlug}/shopping-lists/{id}",
      path_params: {fleetSlug: @fleet.slug, id: @kit.id} do
      assert_equal [1, 2], parsed_body["items"].pluck("quantity")
      assert_equal 3, parsed_body["totals"]["quantity"]
    end
  end

  test "GET a list hidden from the member answers 404" do
    sign_in @member

    assert_api_response :get, 404, api_path: "/fleets/{fleetSlug}/shopping-lists/{id}",
      path_params: {fleetSlug: @fleet.slug, id: @rescue_kit.id}
  end

  test "POST publishes one of the user's own lists without its pins" do
    cart = create(:cart, user: @admin)
    price = create(:item_price, item: @armor, price_type: :sell)
    create(:cart_item, cart:, item: @armor, quantity: 4, item_price: price)
    sign_in @admin

    assert_api_response :post, 201, path_params: {fleetSlug: @fleet.slug},
      body: {name: "Mining kit", visibility: "squadron_only", fleetSquadronIds: [@squadron.id], cartId: cart.id} do
      assert_equal ["Mining kit", "squadron_only", 1, 4],
        parsed_body.values_at("name", "visibility", "linesCount", "itemsCount")
      assert_equal ["Rescue"], parsed_body["fleetSquadrons"].pluck("name")
    end

    assert_equal [[@armor.id, 4]], FleetShoppingList.find_by!(name: "Mining kit").fleet_shopping_list_items.pluck(:item_id, :quantity)
  end

  test "POST is forbidden to a member without the create privilege" do
    sign_in @member

    assert_api_response :post, 403, path_params: {fleetSlug: @fleet.slug},
      body: {name: "Mining kit", cartId: create(:cart, user: @member).id}
  end

  test "POST answers 404 for another user's list" do
    sign_in @admin

    assert_api_response :post, 404, path_params: {fleetSlug: @fleet.slug},
      body: {name: "Mining kit", cartId: create(:cart).id}
  end

  test "POST answers 400 for a name the fleet already uses" do
    sign_in @admin

    assert_api_response :post, 400, path_params: {fleetSlug: @fleet.slug},
      body: {name: "standard KIT", cartId: create(:cart, user: @admin).id}
  end

  test "PUT with a list replaces every line" do
    cart = create(:cart, user: @admin)
    create(:cart_item, cart:, item: @helmet, quantity: 5)
    sign_in @admin

    assert_api_response :put, 200, api_path: "/fleets/{fleetSlug}/shopping-lists/{id}",
      path_params: {fleetSlug: @fleet.slug, id: @kit.id}, body: {name: "Standard kit v2", cartId: cart.id} do
      assert_equal ["Standard kit v2", 1, 5], parsed_body.values_at("name", "linesCount", "itemsCount")
    end
  end

  test "PUT without a list leaves the lines alone" do
    sign_in @admin

    assert_api_response :put, 200, api_path: "/fleets/{fleetSlug}/shopping-lists/{id}",
      path_params: {fleetSlug: @fleet.slug, id: @kit.id}, body: {description: "Buy before the op"} do
      assert_equal ["Buy before the op", 2], parsed_body.values_at("description", "linesCount")
    end
  end

  test "PUT squadron only without a squadron answers 400" do
    sign_in @admin

    assert_api_response :put, 400, api_path: "/fleets/{fleetSlug}/shopping-lists/{id}",
      path_params: {fleetSlug: @fleet.slug, id: @kit.id}, body: {visibility: "squadron_only", fleetSquadronIds: []}
  end

  test "PUT is forbidden to a member" do
    sign_in @member

    assert_api_response :put, 403, api_path: "/fleets/{fleetSlug}/shopping-lists/{id}",
      path_params: {fleetSlug: @fleet.slug, id: @kit.id}, body: {name: "Mine now"}
  end

  test "DELETE removes the list" do
    sign_in @admin

    assert_api_response :delete, 200, api_path: "/fleets/{fleetSlug}/shopping-lists/{id}",
      path_params: {fleetSlug: @fleet.slug, id: @kit.id}

    refute FleetShoppingList.exists?(@kit.id)
    assert_equal 0, FleetShoppingListItem.where(fleet_shopping_list_id: @kit.id).count
  end

  test "DELETE is forbidden to a member" do
    sign_in @member

    assert_api_response :delete, 403, api_path: "/fleets/{fleetSlug}/shopping-lists/{id}",
      path_params: {fleetSlug: @fleet.slug, id: @kit.id}
  end

  test "POST copy starts a new active list named after the fleet's" do
    create(:cart, user: @member, name: "Standard kit")
    sign_in @member

    assert_api_response :post, 200, api_path: "/fleets/{fleetSlug}/shopping-lists/{id}/copy",
      path_params: {fleetSlug: @fleet.slug, id: @kit.id}, body: {} do
      assert_equal ["Standard kit (2)", true], parsed_body.values_at("name", "active")
      assert_equal [1, 2], parsed_body["items"].pluck("quantity")
    end
  end

  test "POST copy adds to the quantities already on the user's list" do
    cart = create(:cart, user: @member, active: false)
    create(:cart_item, cart:, item: @helmet, quantity: 3)
    sign_in @member

    assert_api_response :post, 200, api_path: "/fleets/{fleetSlug}/shopping-lists/{id}/copy",
      path_params: {fleetSlug: @fleet.slug, id: @kit.id}, body: {cartId: cart.id} do
      assert_equal [cart.id, false], parsed_body.values_at("id", "active")
    end

    assert_equal({@helmet.id => 5, @armor.id => 1}, cart.cart_items.pluck(:item_id, :quantity).to_h)
  end

  test "POST copy into a full list changes nothing" do
    cart = create(:cart, user: @member)
    create(:cart_item, cart:, item: @armor)
    CartItem.insert_all!(Array.new(CartItem::MAX_PER_CART - 1) do
      {cart_id: cart.id, item_type: "Commodity", item_id: SecureRandom.uuid, quantity: 1}
    end)
    sign_in @member

    assert_api_response :post, 400, api_path: "/fleets/{fleetSlug}/shopping-lists/{id}/copy",
      path_params: {fleetSlug: @fleet.slug, id: @kit.id}, body: {cartId: cart.id}

    assert_equal 1, cart.cart_items.find_by!(item: @armor).quantity
    refute cart.cart_items.exists?(item_id: @helmet.id)
  end

  test "POST copy of a list hidden from the member answers 404" do
    sign_in @member

    assert_api_response :post, 404, api_path: "/fleets/{fleetSlug}/shopping-lists/{id}/copy",
      path_params: {fleetSlug: @fleet.slug, id: @officers_kit.id}, body: {}
  end
end
