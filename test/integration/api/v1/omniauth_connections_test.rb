# frozen_string_literal: true

require "openapi_helper"

class Api::V1::OmniauthConnectionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/omniauth-connections/{provider}" do
    parameter name: :provider, in: :path, schema: {type: :string}, required: true

    delete("Disconnect OAuth provider") do
      operationId "disconnectOauthProvider"
      tags "OmniAuth Connections"
      produces "application/json"

      security [{SessionCookie: []}]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/User"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden - last connection for oauth-only user") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "DELETE /omniauth-connections/:provider disconnects the provider" do
    user = create(:user, password: "enterprise", password_set_manually: true)
    create(:omniauth_connection, user: user, provider: :discord)
    sign_in user

    assert_api_response :delete, 200, path_params: {provider: "discord"}

    assert_equal 0, user.reload.omniauth_connections.count
  end

  test "DELETE /omniauth-connections/:provider returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {provider: "discord"}
  end

  test "DELETE /omniauth-connections/:provider returns 403 when removing last connection of oauth-only user" do
    user = create(:user, :oauth_only)
    sign_in user

    assert_api_response :delete, 403, path_params: {provider: user.omniauth_connections.first.provider}
  end
end
