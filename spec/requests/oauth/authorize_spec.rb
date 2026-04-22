# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "oauth/authorize", type: :openapi, openapi_schema_name: :"oauth/v1/schema" do
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

      parameter name: :client_id, in: :query, schema: { type: :string }, required: true
      parameter name: :redirect_uri, in: :query, schema: { type: :string }, required: true
      parameter name: :response_type, in: :query, schema: { type: :string }, required: true
      parameter name: :scope, in: :query, schema: { type: :string }, required: true
      parameter name: :state, in: :query, schema: { type: :string }, required: false
      parameter name: :code_challenge, in: :query, schema: { type: :string }, required: false
      parameter name: :code_challenge_method, in: :query, schema: { type: :string }, required: false

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

      request_body required: true, schema: {"$ref": "#/components/schemas/OauthAuthorizationInput"}

      security [{
        SessionCookie: []
      }]

      let(:request_body) do
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

      request_body required: true, schema: {"$ref": "#/components/schemas/OauthAuthorizationInput"}

      security [{
        SessionCookie: []
      }]

      let(:request_body) do
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
