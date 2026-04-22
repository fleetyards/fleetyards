# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/oauth_applications", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:oauth_applications]) }
  let(:oauth_application) { create(:oauth_application) }
  let(:id) { oauth_application.id }

  before do
    sign_in(user) if user.present?
  end

  path "/oauth-applications/{id}" do
    parameter name: "id", in: :path, description: "OAuth Application id", schema: {type: :string, format: :uuid}

    delete("Destroy OAuth Application") do
      operationId "destroyOauthApplication"
      tags "OauthApplications"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/OauthApplication"

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
