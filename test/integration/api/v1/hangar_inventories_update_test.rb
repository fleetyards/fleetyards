# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoriesUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventories/{slug}" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Inventory slug"

    put("Update Hangar Inventory") do
      operationId "updateHangarInventory"
      tags "HangarInventories"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarInventoryUpdateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::Logistics::HangarInventory
      end

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

  test "PUT /hangar/inventories/:slug updates the inventory" do
    sign_in @user

    assert_api_response :put, 200,
      path_params: {slug: @inventory.slug},
      body: {name: "Renamed Locker", location: "Lorville"} do
      assert_equal "Renamed Locker", parsed_body["name"]
      assert_equal "Lorville", parsed_body["location"]
    end
  end

  # The picture somebody picked, held next to the attachment rather than as one:
  # the art it names ships with the app, not with the record.
  test "PUT /hangar/inventories/:slug records the picture that was picked" do
    sign_in @user

    assert_api_response :put, 200,
      path_params: {slug: @inventory.slug},
      body: {imagePreset: "bg-hangar"} do
      assert_equal "bg-hangar", parsed_body["imagePreset"]
    end

    assert_equal "bg-hangar", @inventory.reload.image_preset
  end

  test "PUT /hangar/inventories/:slug clears the picture that was picked" do
    @inventory.update!(image_preset: "bg-hangar")
    sign_in @user

    assert_api_response :put, 200,
      path_params: {slug: @inventory.slug},
      body: {imagePreset: nil} do
      assert_nil parsed_body["imagePreset"]
    end

    assert_nil @inventory.reload.image_preset
  end

  test "PUT /hangar/inventories/:slug clears a linked place, text and link" do
    lorville = create(:location, name: "Lorville", kind: "city")
    @inventory.update!(location: "Lorville", location_id: lorville.id)
    sign_in @user

    assert_api_response :put, 200,
      path_params: {slug: @inventory.slug},
      body: {location: nil, locationId: nil} do
      assert_nil parsed_body["location"]
      assert_nil parsed_body["linkedLocation"]
    end

    assert_nil @inventory.reload.location
    assert_nil @inventory.location_id
  end

  test "PUT /hangar/inventories/:slug returns 404 for another user's inventory" do
    sign_in @other_user

    assert_api_response :put, 404,
      path_params: {slug: @inventory.slug},
      body: {name: "Hijacked"}
  end

  test "PUT /hangar/inventories/:slug returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {slug: @inventory.slug},
      body: {name: "Renamed Locker"}
  end

  test "PUT /hangar/inventories/:slug with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {slug: @inventory.slug},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {name: "OAuth Rename"}
  end
  # A plain request rather than the DSL: declaring this 400 would replace the
  # schema-validation 400 the document already carries for the endpoint.
  test "PUT /hangar/inventories/:slug refuses to rename the personal inventory" do
    personal = Inventory.personal_for(@user)
    sign_in @user

    put "/api/v1/hangar/inventories/#{personal.slug}", params: {name: "Renamed"}, as: :json

    assert_response :bad_request
    assert_equal Inventory::PERSONAL_NAME, personal.reload.name
  end

  test "PUT /hangar/inventories/:slug still edits the rest of the personal inventory" do
    personal = Inventory.personal_for(@user)
    sign_in @user

    put "/api/v1/hangar/inventories/#{personal.slug}", params: {description: "Odds and ends"}, as: :json

    assert_response :ok
    assert_equal "Odds and ends", personal.reload.description
  end
end
