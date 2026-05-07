# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/oauth_applications", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:oauth_applications]) }
  let(:request_body) do
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

      request_body required: true, schema: {"$ref": "#/components/schemas/OauthApplicationInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/OauthApplication"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Admin App")
        end
      end

      include_examples "admin_auth"
    end
  end
end
