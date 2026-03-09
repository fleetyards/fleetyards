# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/oauth_applications", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user) }
  let(:oauth_application) { create(:oauth_application, owner: user) }
  let(:id) { oauth_application.id }

  before do
    Flipper.enable("oauth-applications")
    sign_in(user) if user.present?
  end

  path "/oauth-applications/{id}" do
    parameter name: "id", in: :path, description: "OAuth Application id", schema: {type: :string, format: :uuid}

    get("OAuth Application detail") do
      operationId "oauthApplication"
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

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:id) { SecureRandom.uuid }

        run_test!
      end
    end
  end
end
