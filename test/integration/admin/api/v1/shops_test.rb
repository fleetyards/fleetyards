# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ShopsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/shops/{id}" do
    parameter name: "id", in: :path, description: "Shop id", schema: {type: :string, format: :uuid}, required: true

    get("Shop Detail") do
      operationId "shop"
      tags "Shops"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Shop
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    put("Update Shop") do
      operationId "updateShop"
      tags "Shops"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::ShopInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Shop
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:locations])
    @shop = Shop.create!(name: "Casaba Outlet", location: create(:location, name: "Everus Harbor", kind: "station"))
  end

  test "GET /shops/{id} returns the shop" do
    sign_in @user

    assert_api_response :get, 200, path_params: {id: @shop.id} do
      assert_equal ["Casaba Outlet", "Everus Harbor"], [parsed_body["name"], parsed_body.dig("location", "name")]
    end
  end

  test "PUT /shops/{id} sets the shop's header picture" do
    sign_in @user

    blob = ActiveStorage::Blob.create_and_upload!(
      io: Rails.root.join("test/fixtures/files/test.png").open,
      filename: "test.png",
      content_type: "image/png"
    )

    assert_api_response :put, 200, path_params: {id: @shop.id}, body: {image: blob.signed_id} do
      assert parsed_body.dig("image", "url").present?
    end

    assert_predicate @shop.reload.image, :attached?
  end

  test "PUT /shops/{id} is refused without the privilege" do
    sign_in create(:admin_user, resource_access: [:missions])

    assert_api_response :put, 403, path_params: {id: @shop.id}, body: {image: nil}
  end

  test "GET /shops/{id} is refused signed out" do
    assert_api_response :get, 401, path_params: {id: @shop.id}
  end
end
