# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetResourceAccessCatalogTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/resource-access-catalog" do
    get("Fleet Resource Access Catalog") do
      operationId "fleetResourceAccessCatalog"
      tags "FleetRoles"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetResourceAccessGroupsList
      end
    end
  end

  test "GET /fleets/resource-access-catalog returns the grouped privilege catalog" do
    assert_api_response :get, 200 do
      keys = parsed_body.map { |group| group["key"] }

      assert_equal FleetRole.privilege_groups.map { |group| group[:key] }, keys
      roles_group = parsed_body.find { |group| group["key"] == "roles" }
      assert_equal "fleet:roles:manage", roles_group["managePrivilege"]
    end
  end
end
