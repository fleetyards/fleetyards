# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::UsersSendPasswordResetTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/users/{id}/send-password-reset" do
    parameter name: "id", in: :path, description: "User id", schema: {type: :string, format: :uuid}

    post("Send Password Reset") do
      operationId "sendUserPasswordReset"
      tags "Users"
      produces "application/json"

      response(204, "no content")

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
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
    @admin = create(:admin_user, resource_access: [:users])
  end

  teardown do
    Sidekiq::Testing.fake!
  end

  test "POST /users/:id/send-password-reset sends a reset email" do
    user = create(:user)
    sign_in @admin

    Sidekiq::Testing.inline!
    ActionMailer::Base.deliveries.clear

    assert_api_response :post, 204, path_params: {id: user.id} do
      assert_equal 1, ActionMailer::Base.deliveries.count
    end
  end

  test "POST /users/:id/send-password-reset returns 404 for missing id" do
    sign_in @admin

    assert_api_response :post, 404, path_params: {id: SecureRandom.uuid}
  end

  test "POST /users/:id/send-password-reset returns 401 when not signed in" do
    user = create(:user)

    assert_api_response :post, 401, path_params: {id: user.id}
  end

  test "POST /users/:id/send-password-reset returns 403 for admin without access" do
    user = create(:user)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, path_params: {id: user.id}
  end
end
