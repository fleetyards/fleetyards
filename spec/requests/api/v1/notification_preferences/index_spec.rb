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
      scopes: ["notifications", "notifications:read"]
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

  path "/notification-preferences" do
    get("List notification preferences") do
      operationId "notificationPreferences"
      tags "NotificationPreferences"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:read"]},
        {OpenId: ["notifications", "notifications:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/NotificationPreference"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(Notification.notification_types.count)
          expect(data.first).to have_key("notificationType")
          expect(data.first).to have_key("app")
          expect(data.first).to have_key("mail")
          expect(data.first).to have_key("push")
          expect(data.first).to have_key("mailAvailable")
        end
      end

      include_examples "oauth_auth"
    end
  end
end
