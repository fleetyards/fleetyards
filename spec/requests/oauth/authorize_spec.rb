# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "oauth/authorize", type: :request, swagger_doc: "oauth/v1/schema.yaml" do
  let(:user) { create(:user) }
  let(:oauth_application) do
    create(:oauth_application,
      owner: user,
      confidential: false,
      redirect_uri: "http://localhost:3000/oauth2-redirect.html")
  end

  before do
    sign_in(user) if user.present?
  end

  path "/authorize" do
    get("Pre-authorize OAuth application") do
      operationId "oauthPreAuthorize"
      tags "OAuth"
      produces "application/json"

      parameter name: :client_id, in: :query, type: :string, required: true
      parameter name: :redirect_uri, in: :query, type: :string, required: true
      parameter name: :response_type, in: :query, type: :string, required: true
      parameter name: :scope, in: :query, type: :string, required: true
      parameter name: :state, in: :query, type: :string, required: false
      parameter name: :code_challenge, in: :query, type: :string, required: false
      parameter name: :code_challenge_method, in: :query, type: :string, required: false

      security [{
        SessionCookie: []
      }]

      let(:client_id) { oauth_application.uid }
      let(:redirect_uri) { "http://localhost:3000/oauth2-redirect.html" }
      let(:response_type) { "code" }
      let(:scope) { "public profile:read" }
      let(:state) { "test-state" }
      let(:code_challenge) { "test-challenge" }
      let(:code_challenge_method) { "S256" }

      response(200, "successful") do
        schema "$ref": "#/components/schemas/OauthPreAuthorization"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["clientId"]).to eq(oauth_application.uid)
          expect(data["clientName"]).to eq(oauth_application.name)
          expect(data["scope"]).to eq("public profile:read")
          expect(data["scopes"]).to be_an(Array)
          expect(data["scopes"].first).to include("name", "description")
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:oauth_application) { create(:oauth_application, confidential: false, redirect_uri: "http://localhost:3000/oauth2-redirect.html") }

        run_test!
      end
    end

    post("Authorize OAuth application") do
      operationId "oauthAuthorize"
      tags "OAuth"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/OauthAuthorizationInput"}, required: true

      security [{
        SessionCookie: []
      }]

      let(:input) do
        {
          clientId: oauth_application.uid,
          redirectUri: "http://localhost:3000/oauth2-redirect.html",
          responseType: "code",
          scope: "public profile:read",
          state: "test-state",
          codeChallenge: "test-challenge",
          codeChallengeMethod: "S256"
        }
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/OauthAuthorizationRedirect"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["status"]).to eq("redirect")
          expect(data["redirect_uri"]).to include("code=")
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:oauth_application) { create(:oauth_application, confidential: false, redirect_uri: "http://localhost:3000/oauth2-redirect.html") }

        run_test!
      end
    end

    delete("Deny OAuth authorization") do
      operationId "oauthDeny"
      tags "OAuth"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/OauthAuthorizationInput"}, required: true

      security [{
        SessionCookie: []
      }]

      let(:input) do
        {
          clientId: oauth_application.uid,
          redirectUri: "http://localhost:3000/oauth2-redirect.html",
          responseType: "code",
          scope: "public profile:read",
          state: "test-state",
          codeChallenge: "test-challenge",
          codeChallengeMethod: "S256"
        }
      end

      response(400, "denied") do
        schema "$ref": "#/components/schemas/OauthAuthorizationRedirect"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["status"]).to eq("redirect")
          expect(data["redirect_uri"]).to include("error=access_denied")
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:oauth_application) { create(:oauth_application, confidential: false, redirect_uri: "http://localhost:3000/oauth2-redirect.html") }

        run_test!
      end
    end
  end
end
