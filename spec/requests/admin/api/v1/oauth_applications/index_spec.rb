# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/oauth_applications", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:oauth_applications]) }

  before do
    create_list(:oauth_application, 3)
    sign_in(user) if user.present?
  end

  path "/oauth-applications" do
    get("OAuth Applications list") do
      operationId "oauthApplications"
      tags "OauthApplications"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: :q, in: :query, schema: {"$ref": "#/components/schemas/OauthApplicationQuery"}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/OauthApplications"

        run_test!
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
