# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/users", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user, password: "enterprise") }
  let(:user) { author }
  let(:input) do
    {
      username: "TestUser"
    }
  end

  let(:Authorization) { nil }
  let(:"X-Access-Confirmation") { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["public"]
    )
  end

  before do
    if user.present?
      sign_in(user)

      post confirm_access_api_v1_sessions_path, params: {password: "enterprise"}, as: :json
    end
  end

  path "/users/account" do
    put("Update My Account") do
      operationId "updateAccount"
      tags "Users"

      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/AccountUpdateInput"}, required: true
      parameter name: "X-Access-Confirmation", in: :header, schema: {type: :string},
        description: "Access confirmation token obtained from confirm-access endpoint. Required when using OAuth/OpenID authentication.",
        required: false

      security [
        { SessionCookie: [] },
        { Oauth2: [] },
        { OpenId: [] }
      ]

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/User"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["username"]).to eq("TestUser")
        end
      end

      response(200, "successful with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }
        let(:"X-Access-Confirmation") do
          verifier = ActiveSupport::MessageVerifier.new(Rails.application.credentials.confirm_access_secret!, purpose: :access_confirmation)
          verifier.generate(author.id, expires_in: 15.minutes)
        end

        run_test!
      end

      response(400, "requires access confirmation with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }

        run_test!
      end

      response(400, "bad request") do
        schema "$ref" => "#/components/schemas/ValidationError"

        let(:input) do
          {
            username: ""
          }
        end

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
