# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::UsersRevokeRsiVerificationTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/users/{id}/rsi-verification" do
    parameter name: "id", in: :path, description: "User id", schema: {type: :string, format: :uuid}

    delete("Revoke a user's RSI handle verification") do
      operationId "revokeUserRsiVerification"
      tags "Users"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::User
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
    @admin = create(:admin_user, resource_access: [:users])
    @user = create(:user)
    @user.verify_rsi_handle("TestPilot", via: :rsi_profile)
    @user.save!
  end

  test "DELETE /users/:id/rsi-verification unverifies the handle" do
    sign_in @admin

    assert_api_response :delete, 200, path_params: {id: @user.id}

    assert_not @user.reload.rsi_handle_verified?
    assert_equal "TestPilot", @user.rsi_handle
  end

  test "DELETE /users/:id/rsi-verification returns 404 for missing id" do
    sign_in @admin

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /users/:id/rsi-verification returns 403 without access to users" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: @user.id}
  end

  test "DELETE /users/:id/rsi-verification returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {id: @user.id}
  end
end
