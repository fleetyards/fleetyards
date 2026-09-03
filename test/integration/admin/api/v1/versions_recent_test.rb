# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::VersionsRecentTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/versions/recent" do
    get("Recent Versions") do
      operationId "recentVersions"
      tags "Versions"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Versions
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /versions/recent returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /versions/recent lists an admin's edit with its author and changes" do
    admin = create(:admin_user, super_admin: true)
    model = create(:model, name: "Before")

    model.author_id = admin.id
    model.update!(name: "After")

    sign_in admin

    assert_api_response :get, 200

    items = response.parsed_body["items"]

    assert_equal 1, items.size
    assert_equal "Model", items.first["itemType"]
    assert_equal admin.username, items.first["author"]["username"]

    name_change = items.first["changes"].find { |change| change["field"] == "name" }

    assert_equal "Before", name_change["from"]
    assert_equal "After", name_change["to"]
  end

  # The whole reason the feed exists is to show admin actions. A version written
  # by a background loader carries no author and is noise here.
  test "GET /versions/recent skips versions with no author" do
    model = create(:model, name: "Before")
    model.update!(name: "After")

    sign_in create(:admin_user, super_admin: true)

    assert_api_response :get, 200

    assert_empty response.parsed_body["items"]
  end

  test "GET /versions/recent only lists item types the admin may see" do
    admin = create(:admin_user, resource_access: [:model_modules])
    model = create(:model, name: "Before")
    # `name` is not in ModelModule's paper_trail `only:` list; `cargo` is.
    model_module = create(:model_module, cargo: 1)

    model.author_id = admin.id
    model.update!(name: "After")

    model_module.author_id = admin.id
    model_module.update!(cargo: 2)

    sign_in admin

    assert_api_response :get, 200

    item_types = response.parsed_body["items"].map { |item| item["itemType"] }

    assert_equal ["ModelModule"], item_types
  end

  # Equipment gained versioning alongside the feed; before that an equipment
  # edit was recorded nowhere at all.
  test "GET /versions/recent lists an equipment edit under its own name" do
    admin = create(:admin_user, super_admin: true)
    equipment = create(:equipment, name: "Before")

    equipment.author_id = admin.id
    equipment.update!(name: "After")

    sign_in admin

    assert_api_response :get, 200

    item = response.parsed_body["items"].first

    assert_equal "Equipment", item["itemType"]
    assert_equal "After", item["itemName"]
    assert_equal admin.username, item["author"]["username"]
  end

  # A user is labelled by username, not by a `name` column it does not have.
  test "GET /versions/recent labels a user edit with its username" do
    admin = create(:admin_user, super_admin: true)
    user = create(:user, rsi_handle: "before")

    user.author_id = admin.id
    user.update!(rsi_handle: "after")

    sign_in admin

    assert_api_response :get, 200

    item = response.parsed_body["items"].first

    assert_equal "User", item["itemType"]
    assert_equal user.username, item["itemName"]
  end

  test "GET /versions/recent returns nothing for an admin with no versioned access" do
    admin = create(:admin_user, resource_access: [:stats])
    model = create(:model, name: "Before")

    model.author_id = admin.id
    model.update!(name: "After")

    sign_in admin

    assert_api_response :get, 200

    assert_empty response.parsed_body["items"]
  end
end
