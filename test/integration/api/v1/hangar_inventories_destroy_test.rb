# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoriesDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventories/{slug}" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Inventory slug"

    delete("Delete Hangar Inventory") do
      operationId "destroyHangarInventory"
      tags "HangarInventories"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "successful")

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("hangar_inventories")
    @user = create(:user)
    @other_user = create(:user)
    @inventory = create(:inventory, holder: @user)
  end

  test "DELETE /hangar/inventories/:slug deletes the inventory" do
    sign_in @user

    assert_difference "Inventory.count", -1 do
      assert_api_response :delete, 204, path_params: {slug: @inventory.slug}
    end
  end

  test "DELETE /hangar/inventories/:slug also deletes its items" do
    create_list(:inventory_item, 2, inventory: @inventory)
    sign_in @user

    assert_difference "InventoryItem.count", -2 do
      assert_api_response :delete, 204, path_params: {slug: @inventory.slug}
    end
  end

  test "DELETE /hangar/inventories/:slug returns 404 for another user's inventory" do
    sign_in @other_user

    assert_api_response :delete, 404, path_params: {slug: @inventory.slug}
  end

  test "DELETE /hangar/inventories/:slug returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {slug: @inventory.slug}
  end

  test "DELETE /hangar/inventories/:slug with OAuth bearer token" do
    assert_api_response :delete, 204,
      path_params: {slug: @inventory.slug},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"])
  end

  # A plain request rather than the DSL: declaring this 400 would replace the
  # schema-validation 400 the document already carries for the endpoint.
  test "DELETE /hangar/inventories/:slug is refused while an open contract delivers into it" do
    contract = create(:fleet_contract, :in_progress, :hangar_destination, created_by: @user,
      destination_inventory: @inventory)
    sign_in @user

    assert_no_difference "Inventory.count" do
      delete "/api/v1/hangar/inventories/#{@inventory.slug}", as: :json
    end

    assert_response :bad_request
    assert_includes response.parsed_body["errors"].flat_map { |error| error["messages"].pluck("message") },
      I18n.t("activerecord.errors.messages.inventory_contract_destination")
    assert_equal @inventory, contract.reload.destination_inventory
  end

  test "DELETE /hangar/inventories/:slug is refused while an expired contract still awaits a delivery" do
    contract = create(:fleet_contract, :in_progress, :hangar_destination, created_by: @user,
      destination_inventory: @inventory)
    create(:inventory_transfer, fleet_contract: contract, recipient: @user)
    contract.update_columns(aasm_state: "expired")
    sign_in @user

    assert_no_difference "Inventory.count" do
      delete "/api/v1/hangar/inventories/#{@inventory.slug}", as: :json
    end

    assert_response :bad_request
  end

  test "DELETE /hangar/inventories/:slug goes through once an expired contract has settled" do
    contract = create(:fleet_contract, :in_progress, :hangar_destination, created_by: @user,
      destination_inventory: @inventory)
    create(:inventory_transfer, fleet_contract: contract, recipient: @user, aasm_state: "declined")
    contract.update_columns(aasm_state: "expired")
    sign_in @user

    assert_difference "Inventory.count", -1 do
      delete "/api/v1/hangar/inventories/#{@inventory.slug}", as: :json
    end

    assert_response :no_content
  end

  # A transport's pickup waits on its crew and can never land in the hangar.
  test "DELETE /hangar/inventories/:slug is not held up by an expired contract's pending pickup" do
    contract = create(:fleet_contract, :in_progress, :hangar_destination, created_by: @user,
      destination_inventory: @inventory)
    create(:inventory_transfer, fleet_contract: contract, recipient: @other_user)
    contract.update_columns(aasm_state: "expired")
    sign_in @user

    assert_difference "Inventory.count", -1 do
      delete "/api/v1/hangar/inventories/#{@inventory.slug}", as: :json
    end

    assert_response :no_content
  end

  test "DELETE /hangar/inventories/:slug goes through once the contract is closed" do
    create(:fleet_contract, :hangar_destination, created_by: @user, destination_inventory: @inventory,
      aasm_state: "fulfilled")
    sign_in @user

    assert_difference "Inventory.count", -1 do
      delete "/api/v1/hangar/inventories/#{@inventory.slug}", as: :json
    end

    assert_response :no_content
  end
end
