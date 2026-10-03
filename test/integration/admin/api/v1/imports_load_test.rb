# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ImportsLoadTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/imports/load" do
    put("Start a Load") do
      operationId "startImportLoad"
      description "Start one of the loads the imports page offers"
      tags "Imports"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::ImportLoadInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::MessageResponse
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
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
    @user = create(:admin_user, resource_access: [:imports])
  end

  test "PUT /imports/load starts the ship matrix load" do
    Loaders::ModelsJob.expects(:perform_async).with(@user.id)
    sign_in @user

    assert_api_response :put, 200, body: {loader: "ship_matrix"}
  end

  # The job, handed an environment alone, would pair it with the default
  # environment's version.
  test "PUT /imports/load loads an sc_data environment by its own build" do
    ptu = ScData::Source.find("ptu")
    skip "no ptu source configured" unless ptu

    Loaders::ScData::AllJob.expects(:perform_async).with(ptu.version, @user.id, "ptu")
    sign_in @user

    assert_api_response :put, 200, body: {loader: "sc_data", environment: "ptu"}
  end

  test "PUT /imports/load loads the default sc_data environment when none is named" do
    default = ScData::Source.default
    Loaders::ScData::AllJob.expects(:perform_async).with(default.version, @user.id, default.environment)
    sign_in @user

    assert_api_response :put, 200, body: {loader: "sc_data"}
  end

  test "PUT /imports/load starts every loader it lists" do
    sign_in @user

    Imports::Loaders::KEYS.each do |loader|
      assert_api_response :put, 200, body: {loader:}
    end
  end

  test "PUT /imports/load rejects an environment it does not know" do
    sign_in @user

    assert_api_response :put, 400, body: {loader: "sc_data", environment: "ptuu"}
  end

  test "PUT /imports/load rejects a loader it does not know" do
    sign_in @user

    assert_api_response :put, 400, body: {loader: "everything"}
  end

  test "PUT /imports/load is refused without the imports privilege" do
    sign_in create(:admin_user, resource_access: [:models])

    assert_api_response :put, 403, body: {loader: "ship_matrix"}
  end

  test "PUT /imports/load is refused signed out" do
    assert_api_response :put, 401, body: {loader: "ship_matrix"}
  end
end
