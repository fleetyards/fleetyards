# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/notifications", type: :request, swagger_doc: "v1/schema.yaml" do
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

  path "/notifications/destroy-all" do
    delete("Delete all notifications") do
      operationId "destroyAllNotifications"
      tags "Notifications"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      response(204, "successful") do
        run_test! do
          expect(author.notifications.count).to eq(0)
        end
      end

      include_examples "oauth_auth", success_status: 204
    end
  end
end
