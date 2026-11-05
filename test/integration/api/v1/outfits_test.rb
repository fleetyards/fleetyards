# frozen_string_literal: true

require "openapi_helper"

class Api::V1::OutfitsTest < ActionDispatch::IntegrationTest
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

  api_path "/outfits" do
    get("Outfits") do
      operationId "outfits"
      tags "DressingRoom"
      produces "application/json"
      security READ_SECURITY

      response(200, "successful") { schema ::V1::Schemas::DressingRoom::OutfitsList }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "feature disabled") { schema ::Shared::V1::Schemas::StandardError }
    end

    post("Create Outfit") do
      operationId "createOutfit"
      tags "DressingRoom"
      consumes "application/json"
      produces "application/json"
      security WRITE_SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::OutfitCreateInput

      response(201, "successful") { schema ::V1::Schemas::DressingRoom::Outfit }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/outfits/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    get("Outfit") do
      operationId "outfit"
      tags "DressingRoom"
      produces "application/json"
      security READ_SECURITY

      response(200, "successful") { schema ::V1::Schemas::DressingRoom::Outfit }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    put("Update Outfit") do
      operationId "updateOutfit"
      tags "DressingRoom"
      consumes "application/json"
      produces "application/json"
      security WRITE_SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::OutfitUpdateInput

      response(200, "successful") { schema ::V1::Schemas::DressingRoom::Outfit }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    delete("Destroy Outfit") do
      operationId "destroyOutfit"
      tags "DressingRoom"
      produces "application/json"
      security WRITE_SECURITY

      response(200, "successful") { schema ::V1::Schemas::SuccessResponse }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    Flipper.enable(:dressing_room)
    @user = create(:user)
    @core = create(:worn_equipment, name: "ADP Core", slot: "torso")
    @legs = create(:worn_equipment, name: "ADP Legs", slot: "legs")
    @helmet = create(:worn_equipment, name: "ADP-mk4 Helmet", slot: "helmet")
    @outfit = create(:outfit, user: @user, name: "Heavy")
    @outfit.update!(item_list: [{slot: "torso", equipment_id: @core.id}])
  end

  test "GET /outfits lists the user's outfits only, with what each wears" do
    create(:outfit, name: "Someone else's")
    sign_in @user

    assert_api_response :get, 200, api_path: "/outfits" do
      assert_equal ["Heavy"], parsed_body.pluck("name")
      assert_equal [["torso", "ADP Core"]], parsed_body.first["items"].map { |item| [item["slot"], item.dig("equipment", "name")] }
    end
  end

  test "GET /outfits returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: "/outfits"
  end

  test "GET /outfits is forbidden while the feature is off" do
    Flipper.disable(:dressing_room)
    sign_in @user

    assert_api_response :get, 403, api_path: "/outfits"
  end

  test "POST /outfits saves an outfit with its items" do
    sign_in @user

    body = {name: "Recon", items: [{slot: "legs", equipmentId: @legs.id}, {slot: "helmet", equipmentId: @helmet.id}]}

    assert_api_response :post, 201, api_path: "/outfits", body: do
      assert_equal "Recon", parsed_body["name"]
      assert_equal %w[helmet legs], parsed_body["items"].pluck("slot").sort
    end
  end

  test "POST /outfits carries a rifle on the back and a pistol in hand" do
    sign_in @user
    rifle = create(:equipment, name: "P4-AR Rifle", sub_type: "Medium")
    pistol = create(:equipment, name: "S-38 Pistol", sub_type: "Small")

    body = {
      name: "Patrol",
      items: [{slot: "primary", equipmentId: rifle.id}, {slot: "sidearm", equipmentId: pistol.id}],
      heldWeapon: "sidearm"
    }

    assert_api_response :post, 201, api_path: "/outfits", body: do
      assert_equal "sidearm", parsed_body["heldWeapon"]
      assert_equal [["primary", "P4-AR Rifle"], ["sidearm", "S-38 Pistol"]],
        parsed_body["items"].map { |item| [item["slot"], item.dig("equipment", "name")] }.sort
    end
  end

  test "POST /outfits keeps the body the outfit is put on" do
    sign_in @user

    assert_api_response :post, 201, api_path: "/outfits", body: {name: "Recon", body: "female"} do
      assert_equal "female", parsed_body["body"]
    end
  end

  test "POST /outfits refuses a pistol on the back and armour in a holster" do
    sign_in @user
    pistol = create(:equipment, sub_type: "Small")

    assert_api_response :post, 400, api_path: "/outfits",
      body: {name: "Wrong", items: [{slot: "primary", equipmentId: pistol.id}]}
    assert_api_response :post, 400, api_path: "/outfits",
      body: {name: "Wrong", items: [{slot: "sidearm", equipmentId: @legs.id}]}
  end

  test "POST /outfits carries gear on the ports of what is worn" do
    sign_in @user
    core = create(:worn_equipment, slot: "torso", fit: worn_fit("grenade_attach_1", "magazine_attach_1"))
    legs = create(:worn_equipment, slot: "legs", fit: worn_fit("medPen_attach_1", "utility_attach_2"))
    knife = create(:equipment, sub_type: "Knife")
    pen = create(:equipment, equipment_type: "medical", sub_type: "MedPack")
    magazine = create(:equipment, equipment_type: "weapon_attachment", sub_type: "Magazine")

    body = {name: "Kitted", items: [
      {slot: "torso", equipmentId: core.id}, {slot: "legs", equipmentId: legs.id},
      {slot: "utility_2", equipmentId: knife.id}, {slot: "medpen_1", equipmentId: pen.id},
      {slot: "magazine_1", equipmentId: magazine.id}
    ]}

    assert_api_response :post, 201, api_path: "/outfits", body: do
      assert_equal %w[legs magazine_1 medpen_1 torso utility_2], parsed_body["items"].pluck("slot").sort
    end
  end

  test "POST /outfits refuses gear no worn piece has a port for" do
    sign_in @user
    core = create(:worn_equipment, slot: "torso", fit: worn_fit("grenade_attach_1"))
    grenade = create(:equipment, sub_type: "Grenade")

    assert_api_response :post, 400, api_path: "/outfits", body: {name: "Loose", items: [{slot: "grenade_1", equipmentId: grenade.id}]}
    assert_api_response :post, 400, api_path: "/outfits", body: {name: "Too many", items: [
      {slot: "torso", equipmentId: core.id}, {slot: "grenade_2", equipmentId: grenade.id}
    ]}
  end

  test "POST /outfits refuses the wrong gear for a slot" do
    sign_in @user
    core = create(:worn_equipment, slot: "torso", fit: worn_fit("grenade_attach_1"))
    knife = create(:equipment, sub_type: "Knife")

    assert_api_response :post, 400, api_path: "/outfits", body: {name: "Wrong", items: [
      {slot: "torso", equipmentId: core.id}, {slot: "grenade_1", equipmentId: knife.id}
    ]}
  end

  test "POST /outfits fills a worn piece's storage, and sends it back" do
    sign_in @user
    pack = create(:worn_equipment, slot: "backpack", inventory: pack_inventory)
    pen = create(:equipment, equipment_type: "medical", sub_type: "MedPack", volume: 0.00018)

    body = {
      name: "Stocked",
      items: [{slot: "backpack", equipmentId: pack.id}],
      storedItems: [{holder: "backpack", equipmentId: pen.id, quantity: 5}]
    }

    assert_api_response :post, 201, api_path: "/outfits", body: do
      stored = parsed_body["storedItems"].sole

      assert_equal ["backpack", 5, pen.name], [stored["holder"], stored["quantity"], stored.dig("equipment", "name")]
    end
  end

  test "POST /outfits refuses more than a piece holds, by volume" do
    sign_in @user
    pack = create(:worn_equipment, slot: "backpack", inventory: pack_inventory(capacity: 900))
    pen = create(:equipment, equipment_type: "medical", sub_type: "MedPack", volume: 0.00018)

    fits = {name: "Full", items: [{slot: "backpack", equipmentId: pack.id}], storedItems: [{holder: "backpack", equipmentId: pen.id, quantity: 5}]}
    assert_api_response :post, 201, api_path: "/outfits", body: fits

    over = {name: "Overfull", items: [{slot: "backpack", equipmentId: pack.id}], storedItems: [{holder: "backpack", equipmentId: pen.id, quantity: 6}]}
    assert_api_response :post, 400, api_path: "/outfits", body: over
  end

  test "POST /outfits refuses an item too long for the interior, however it is turned" do
    sign_in @user
    pack = create(:worn_equipment, slot: "backpack", inventory: pack_inventory)
    rifle = create(:equipment, sub_type: "Medium", volume: 0.001, volume_dimensions: {x: 1.2, y: 0.1, z: 0.1})
    turned = create(:equipment, sub_type: "Medium", volume: 0.001, volume_dimensions: {x: 0.1, y: 0.1, z: 0.9})

    worn = [{slot: "backpack", equipmentId: pack.id}]

    assert_api_response :post, 400, api_path: "/outfits",
      body: {name: "Long", items: worn, storedItems: [{holder: "backpack", equipmentId: rifle.id, quantity: 1}]}
    assert_api_response :post, 201, api_path: "/outfits",
      body: {name: "Turned", items: worn, storedItems: [{holder: "backpack", equipmentId: turned.id, quantity: 1}]}
  end

  test "POST /outfits refuses storage in a piece not worn, without storage, or an unmeasured item" do
    sign_in @user
    bare = create(:worn_equipment, slot: "backpack")
    pack = create(:worn_equipment, slot: "backpack", inventory: pack_inventory)
    pen = create(:equipment, volume: 0.00018)
    unmeasured = create(:equipment, volume: nil)

    stored = [{holder: "backpack", equipmentId: pen.id, quantity: 1}]

    assert_api_response :post, 400, api_path: "/outfits", body: {name: "Nothing worn", storedItems: stored}
    assert_api_response :post, 400, api_path: "/outfits",
      body: {name: "No storage", items: [{slot: "backpack", equipmentId: bare.id}], storedItems: stored}
    assert_api_response :post, 400, api_path: "/outfits",
      body: {name: "Unmeasured", items: [{slot: "backpack", equipmentId: pack.id}],
             storedItems: [{holder: "backpack", equipmentId: unmeasured.id, quantity: 1}]}
  end

  test "PUT /outfits/{id} replaces what is stored, and keeps it when it is not sent" do
    sign_in @user
    pack = create(:worn_equipment, slot: "backpack", inventory: pack_inventory)
    pen = create(:equipment, volume: 0.00018)
    bar = create(:equipment, volume: 0.0005)
    @outfit.update!(
      item_list: [{slot: "backpack", equipment_id: pack.id}],
      stored_item_list: [{holder: "backpack", equipment_id: pen.id, quantity: 2}]
    )

    assert_api_response :put, 200, path_params: {id: @outfit.id}, body: {name: "Renamed"} do
      assert_equal [2], parsed_body["storedItems"].pluck("quantity")
    end

    assert_api_response :put, 200, path_params: {id: @outfit.id},
      body: {storedItems: [{holder: "backpack", equipmentId: bar.id, quantity: 1}]} do
      assert_equal [bar.name], parsed_body["storedItems"].map { |item| item.dig("equipment", "name") }
    end
  end

  test "PUT /outfits/{id} still renames an outfit a patch left with gear on a lost port" do
    sign_in @user
    grenade = create(:equipment, sub_type: "Grenade")
    core = create(:worn_equipment, slot: "torso", fit: worn_fit("grenade_attach_1"))
    @outfit.update!(item_list: [{slot: "torso", equipment_id: core.id}, {slot: "grenade_1", equipment_id: grenade.id}])
    core.update!(fit: worn_fit)

    assert_api_response :put, 200, path_params: {id: @outfit.id}, body: {name: "Renamed"}
  end

  test "an item that is deleted leaves the storage it was kept in" do
    pack = create(:worn_equipment, slot: "backpack", inventory: pack_inventory)
    pen = create(:equipment, volume: 0.00018)
    @outfit.update!(
      item_list: [{slot: "backpack", equipment_id: pack.id}],
      stored_item_list: [{holder: "backpack", equipment_id: pen.id, quantity: 1}]
    )

    pen.destroy!

    assert_empty @outfit.reload.stored_items
  end

  test "POST /outfits refuses to hold a weapon the outfit does not carry" do
    sign_in @user

    assert_api_response :post, 400, api_path: "/outfits", body: {name: "Empty handed", heldWeapon: "primary"}
  end

  test "POST /outfits refuses an item in a slot it does not fit" do
    sign_in @user

    assert_api_response :post, 400, api_path: "/outfits", body: {name: "Wrong", items: [{slot: "helmet", equipmentId: @legs.id}]}

    assert_not Outfit.exists?(name: "Wrong")
  end

  test "POST /outfits refuses a name the user already has" do
    sign_in @user

    assert_api_response :post, 400, api_path: "/outfits", body: {name: "Heavy"}
  end

  test "POST /outfits answers a name lost to a concurrent save as taken" do
    sign_in @user
    Outfit.any_instance.stubs(:save).raises(ActiveRecord::RecordNotUnique)

    assert_api_response :post, 400, api_path: "/outfits", body: {name: "Raced"} do
      assert_equal "validation_error.outfits.create", parsed_body["code"]
    end
  end

  test "an equipment item that is deleted leaves the outfits that wore it" do
    @core.destroy!

    assert_empty @outfit.reload.items
  end

  test "a deleted weapon leaves the outfit that held it empty-handed" do
    pistol = create(:equipment, sub_type: "Small")
    @outfit.update!(item_list: [{slot: "sidearm", equipment_id: pistol.id}], held_weapon: "sidearm")

    pistol.destroy!

    assert_nil @outfit.reload.held_weapon
    assert @outfit.valid?
  end

  test "PUT /outfits/{id} answers a slot filled by a concurrent save as taken, not the name" do
    sign_in @user
    Outfit.any_instance.stubs(:save).raises(ActiveRecord::RecordNotUnique, "index_outfit_items_on_outfit_id_and_slot")

    assert_api_response :put, 400, path_params: {id: @outfit.id}, body: {name: "Heavy"} do
      assert parsed_body["errors"].any? { |error| error["attribute"] == "items" }
    end
  end

  test "GET /outfits/{id} returns 404 for another user's outfit" do
    sign_in create(:user)

    assert_api_response :get, 404, path_params: {id: @outfit.id}
  end

  test "PUT /outfits/{id} replaces what the outfit wears" do
    sign_in @user

    body = {name: "Heavy Mk2", items: [{slot: "torso", equipmentId: @core.id}, {slot: "legs", equipmentId: @legs.id}]}

    assert_api_response :put, 200, path_params: {id: @outfit.id}, body: do
      assert_equal "Heavy Mk2", parsed_body["name"]
      assert_equal %w[legs torso], parsed_body["items"].pluck("slot").sort
    end

    assert_api_response :put, 200, path_params: {id: @outfit.id}, body: {items: [{slot: "legs", equipmentId: @legs.id}]} do
      assert_equal %w[legs], parsed_body["items"].pluck("slot")
    end
  end

  test "PUT /outfits/{id} keeps the items when only the name changes" do
    sign_in @user

    assert_api_response :put, 200, path_params: {id: @outfit.id}, body: {name: "Renamed"} do
      assert_equal %w[torso], parsed_body["items"].pluck("slot")
    end
  end

  test "DELETE /outfits/{id} removes the outfit and its items" do
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: @outfit.id}

    assert_not Outfit.exists?(@outfit.id)
    assert_equal 0, OutfitItem.where(outfit_id: @outfit.id).count
  end

  private def worn_fit(*ports)
    {"type" => "Char_Armor_Torso", "ports" => ports.map { |name| {"name" => name} }}
  end

  private def pack_inventory(capacity: 150_000)
    {"capacity" => capacity, "dimensions" => {"x" => 0.64, "y" => 1.0, "z" => 0.45}}
  end
end
