# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/notifications", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:author) { create(:user) }
  let(:user) { author }
  let!(:notifications) { create_list(:notification, 3, user: author) }

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

  path "/notifications/read-all" do
    put("Mark all notifications as read") do
      operationId "readAllNotifications"
      tags "Notifications"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      response(204, "successful") do
        run_test! do
          expect(author.notifications.unread.count).to eq(0)
        end
      end

      include_examples "oauth_auth", success_status: 204
    end
  end
end
