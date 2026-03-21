# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/sessions", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:password) { "enterprise" }
  let(:author) { create(:user, password:) }
  let(:user) { author }
  let(:input) do
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

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ConfirmAccessInput"}, required: true

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

        let(:input) { nil }

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
