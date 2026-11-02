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
end
