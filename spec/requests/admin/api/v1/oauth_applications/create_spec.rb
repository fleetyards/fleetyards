# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/oauth_applications", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:oauth_applications]) }
  let(:input) do
    {
      name: "Admin App",
      redirectUri: "https://example.com/callback",
      confidential: true
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/oauth-applications" do
    post("Create OAuth Application") do
      operationId "createOauthApplication"
      tags "OauthApplications"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/OauthApplicationInput"}, required: true

      response(201, "successful") do
        schema "$ref": "#/components/schemas/OauthApplication"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Admin App")
        end
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:admin_user, resource_access: []) }

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
