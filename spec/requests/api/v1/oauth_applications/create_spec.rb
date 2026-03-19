# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/oauth_applications", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user) }
  let(:input) do
    {
      name: "My App",
      redirectUri: "https://example.com/callback",
      confidential: true
    }
  end

  before do
    Flipper.enable("oauth-applications")
    sign_in(user) if user.present?
  end

  path "/oauth-applications" do
    post("Create OAuth Application") do
      operationId "createOauthApplication"
      tags "OauthApplications"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/OauthApplicationInput"}, required: true

      security [{
        SessionCookie: [],
        Oauth2: [],
        OpenId: []
      }]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/OauthApplicationWithSecret"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("My App")
        end
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:input) { {name: ""} }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
