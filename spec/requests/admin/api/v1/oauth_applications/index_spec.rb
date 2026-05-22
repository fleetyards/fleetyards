# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/oauth_applications", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
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
      parameter name: :q, in: :query, schema: {type: :object, "$ref": "#/components/schemas/OauthApplicationQuery"}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/OauthApplications"

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
