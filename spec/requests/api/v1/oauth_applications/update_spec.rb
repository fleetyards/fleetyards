# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/oauth_applications", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user) }
  let(:oauth_application) { create(:oauth_application, owner: user) }
  let(:id) { oauth_application.id }
  let(:input) do
    {
      name: "Updated App"
    }
  end

  before do
    Flipper.enable("oauth-applications")
    sign_in(user) if user.present?
  end

  path "/oauth-applications/{id}" do
    parameter name: "id", in: :path, description: "OAuth Application id", schema: {type: :string, format: :uuid}

    put("Update OAuth Application") do
      operationId "updateOauthApplication"
      tags "OauthApplications"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/OauthApplicationUpdateInput"}, required: true

      security [{
        SessionCookie: [],
        Oauth2: [],
        OpenId: []
      }]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/OauthApplication"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Updated App")
        end
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
