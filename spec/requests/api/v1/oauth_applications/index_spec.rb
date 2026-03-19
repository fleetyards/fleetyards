# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/oauth_applications", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user) }

  before do
    Flipper.enable("oauth-applications")
    sign_in(user) if user.present?
  end

  path "/oauth-applications" do
    get("OAuth Applications list") do
      operationId "oauthApplications"
      tags "OauthApplications"
      produces "application/json"

      security [{
        SessionCookie: [],
        Oauth2: [],
        OpenId: []
      }]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/OauthApplication"}

        before do
          create_list(:oauth_application, 3, owner: user)
        end

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
