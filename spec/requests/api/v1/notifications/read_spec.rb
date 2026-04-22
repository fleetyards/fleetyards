# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/notifications", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:notification) { create(:notification, user: author) }

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

  path "/notifications/{id}/read" do
    parameter name: "id", in: :path, schema: { type: :string }, required: true

    put("Mark notification as read") do
      operationId "readNotification"
      tags "Notifications"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      let(:id) { notification.id }

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Notification"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["read"]).to be true
          expect(data["readAt"]).to be_present
        end
      end

      include_examples "oauth_auth"

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:id) { notification.id }

        run_test!
      end
    end
  end
end
