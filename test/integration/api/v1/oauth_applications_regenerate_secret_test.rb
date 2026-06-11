# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::OauthApplicationsRegenerateSecretTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/oauth-applications/{id}/regenerate-secret" do
    parameter name: "id", in: :path, description: "OAuth Application id", schema: {type: :string, format: :uuid}

    put("Regenerate OAuth Application secret") do
      operationId "regenerateOauthApplicationSecret"
      tags "OauthApplications"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/OauthApplicationWithSecret"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("oauth-applications")
    @user = create(:user)
  end

  test "PUT /oauth-applications/:id/regenerate-secret returns a new secret" do
    app = create(:oauth_application, owner: @user)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: app.id}, body: {}
  end

  test "PUT /oauth-applications/:id/regenerate-secret returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {}
  end

  test "PUT /oauth-applications/:id/regenerate-secret returns 401 when not signed in" do
    app = create(:oauth_application, owner: @user)

    assert_api_response :put, 401, path_params: {id: app.id}, body: {}
  end
end
