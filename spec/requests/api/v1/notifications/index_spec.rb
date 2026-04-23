# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/notifications", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:author) { create(:user) }
  let(:user) { author }
  let!(:notifications) { create_list(:notification, 3, user: author) }
  let!(:expired_notification) { create(:notification, :expired, user: author) }

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

  path "/notifications" do
    get("List notifications") do
      operationId "notifications"
      tags "Notifications"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:read"]},
        {OpenId: ["notifications", "notifications:read"]}
      ]

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {
        type: :string, default: Notification.default_per_page
      }, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Notifications"

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(3)
        end
      end

      include_examples "oauth_auth"

      response(200, "successful with type filter", hidden: true) do
        schema "$ref": "#/components/schemas/Notifications"

        let(:q) do
          {"notification_type_eq" => "hangar_create"}
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(3)
        end
      end
    end
  end
end
