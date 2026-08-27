# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::EquipmentWeaponClassesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/equipment/weapon_class_filters" do
    get("Equipment weapon classes") do
      operationId "equipmentWeaponClasses"
      tags "Equipment"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
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
    @user = create(:admin_user, resource_access: [:equipment])
  end

  test "GET /equipment/weapon_class_filters returns the classes in use as filter options" do
    create(:equipment, weapon_class: "energy")
    create(:equipment, weapon_class: "ballistic")
    create(:equipment, :attachment)

    sign_in @user

    assert_api_response :get, 200 do
      assert_equal %w[ballistic energy], parsed_body.map { |filter| filter["value"] }
      assert(parsed_body.all? { |filter| filter["label"].present? })
      assert(parsed_body.all? { |filter| filter["category"] == "weapon_class" })
    end
  end

  # The column is a free string precisely so a class the constant does not list
  # still loads, and the picker has to offer it or the rows are unreachable.
  test "GET /equipment/weapon_class_filters offers a class WEAPON_CLASSES does not list" do
    create(:equipment, weapon_class: "distortion")

    sign_in @user

    assert_api_response :get, 200 do
      assert_equal %w[distortion], parsed_body.map { |filter| filter["value"] }
      assert_not_includes Equipment::WEAPON_CLASSES, "distortion"
    end
  end

  test "GET /equipment/weapon_class_filters skips hidden gear" do
    create(:equipment, :hidden, weapon_class: "energy")

    sign_in @user

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /equipment/weapon_class_filters returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /equipment/weapon_class_filters returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
