# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarSearchTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/search" do
    get("Search the current user's hangar") do
      operationId "hangarSearch"
      tags "Search"
      produces "application/json"

      parameter name: "q", in: :query, schema: {type: :string}, required: true

      response(200, "successful") do
        schema ::V1::Schemas::SearchResults
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)
    @other = create(:user)
  end

  def groups
    parsed_body["groups"].to_h { |group| [group["type"], group["items"].pluck("name")] }
  end

  test "GET /hangar/search refuses a visitor" do
    assert_api_response :get, 401, params: {q: "omni"}
  end

  test "GET /hangar/search finds a user's own things, one group per list" do
    model = create(:model, name: "Omni Hauler")
    create(:vehicle, user: @user, model:)
    create(:vehicle, :wanted, user: @user, model: create(:model, name: "Omni Scout"))
    create(:user_blueprint, user: @user, blueprint: create(:blueprint, name: "Omni Rifle"))
    create(:inventory_item, inventory: create(:inventory, holder: @user, name: "Depot"), name: "Omni Ore")
    create(:hangar_pledge_item, user: @user, kind: "paint", name: "Omni Paint")
    create(:buyback_pledge, user: @user, name: "Omni Pack")
    sign_in @user

    assert_api_response :get, 200, params: {q: "omni"} do
      assert_equal(
        {
          "HangarVehicle" => ["Omni Hauler"],
          "WishlistVehicle" => ["Omni Scout"],
          "OwnedBlueprint" => ["Omni Rifle"],
          "InventoryItem" => ["Omni Ore"],
          "Paint" => ["Omni Paint"],
          "Buyback" => ["Omni Pack"]
        },
        groups
      )
    end
  end

  test "GET /hangar/search never returns another user's things" do
    create(:vehicle, user: @other, model: create(:model, name: "Omni Hauler"))
    create(:vehicle, :wanted, user: @other, model: create(:model, name: "Omni Scout"))
    create(:user_blueprint, user: @other, blueprint: create(:blueprint, name: "Omni Rifle"))
    create(:inventory_item, inventory: create(:inventory, holder: @other), name: "Omni Ore")
    create(:hangar_pledge_item, user: @other, name: "Omni Paint")
    create(:buyback_pledge, user: @other, name: "Omni Pack")
    sign_in @user

    assert_api_response :get, 200, params: {q: "omni"} do
      assert_empty parsed_body["groups"]
    end
  end

  test "GET /hangar/search leaves out what the hangar list hides" do
    model = create(:model, name: "Omni Hauler")
    create(:vehicle, :loaner, user: @user, model:)
    create(:vehicle, user: @user, model:, hidden_by_user: true)
    sign_in @user

    assert_api_response :get, 200, params: {q: "omni"} do
      assert_empty parsed_body["groups"]
    end
  end

  test "GET /hangar/search says when a list has more than it offers" do
    6.times { |n| create(:hangar_pledge_item, user: @user, kind: "paint", name: "Omni Paint #{n}") }
    sign_in @user

    assert_api_response :get, 200, params: {q: "omni"} do
      group = parsed_body["groups"].first

      assert_equal 5, group["items"].size
      assert_equal true, group["hasMore"]
    end
  end
end
