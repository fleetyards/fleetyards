# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ModelsReloadLoanersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/models/reload-loaners" do
    put("Reload Loaners") do
      operationId "reloadLoaners"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema type: :object, properties: {message: {type: :string}}, required: [:message]
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:models])
  end

  test "PUT /models/reload-loaners enqueues the loader" do
    Loaders::LoanerJob.stubs(:perform_async)
    sign_in @user

    assert_api_response :put, 200, body: {}
  end

  test "PUT /models/reload-loaners returns 401 when not signed in" do
    assert_api_response :put, 401, body: {}
  end

  test "PUT /models/reload-loaners returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, body: {}
  end
end
