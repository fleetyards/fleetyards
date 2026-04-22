# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/notifications", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:author) { create(:user) }
  let(:user) { author }
  let!(:notification) { create(:notification, user: author) }

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

  path "/notifications/{id}" do
    parameter name: "id", in: :path, type: :string, required: true

    delete("Delete a notification") do
      operationId "destroyNotification"
      tags "Notifications"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      let(:id) { notification.id }

      response(204, "successful") do
        run_test! do
          expect(Notification.find_by(id: notification.id)).to be_nil
        end
      end

      include_examples "oauth_auth", success_status: 204

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:id) { notification.id }

        run_test!
      end
    end
  end
end
