# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/oauth_applications", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:oauth_application) { create(:oauth_application, owner: author) }
  let(:id) { oauth_application.id }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["public"]
    )
  end

  before do
    Flipper.enable("oauth-applications")
    sign_in(user) if user.present?
  end

  path "/oauth-applications/{id}" do
    parameter name: "id", in: :path, description: "OAuth Application id", schema: {type: :string, format: :uuid}

    delete("Destroy OAuth Application") do
      operationId "destroyOauthApplication"
      tags "OauthApplications"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(204, "successful") do
        run_test!
      end

      response(204, "successful with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:id) { SecureRandom.uuid }

        run_test!
      end
    end
  end
end
