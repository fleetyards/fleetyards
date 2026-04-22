# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/sessions", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:password) { "enterprise" }
  let(:author) { create(:user, password:) }
  let(:user) { author }
  let(:request_body) do
    {
      password: password
    }
  end

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["public"]
    )
  end

  before do
    sign_in(user) if user.present?
  end

  path "/sessions/confirm-access" do
    post("confirm_access session") do
      operationId "confirmAccess"
      tags "Sessions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ConfirmAccessInput"}

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        run_test!
      end

      response(200, "successful with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["token"]).to be_present
        end
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:request_body) { nil }

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
