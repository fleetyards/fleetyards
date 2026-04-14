# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/notification_preferences", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["notifications", "notifications:write"]
    )
  end
  let(:wrong_scope_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["public"]
    )
  end

  before do
    sign_in(user) if user.present?
  end

  path "/notification-preferences/{id}" do
    parameter name: "id", in: :path, type: :string, required: true

    put("Update a notification preference") do
      operationId "updateNotificationPreference"
      tags "NotificationPreferences"
      consumes "application/json"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      parameter name: :input, in: :body, schema: {
        type: :object,
        properties: {
          app: {type: :boolean},
          mail: {type: :boolean},
          push: {type: :boolean}
        }
      }

      let(:id) { "hangar_create" }
      let(:input) { {app: false} }

      response(200, "successful") do
        schema "$ref": "#/components/schemas/NotificationPreference"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["notificationType"]).to eq("hangar_create")
          expect(data["app"]).to be false
        end
      end

      response(200, "successful with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }

        run_test!
      end

      response(404, "not found for invalid type") do
        let(:id) { "invalid_type" }

        run_test!
      end

      response(401, "unauthorized with wrong scope token") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:Authorization) { "Bearer #{wrong_scope_access_token.token}" }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:id) { "hangar_create" }

        run_test!
      end
    end
  end
end
