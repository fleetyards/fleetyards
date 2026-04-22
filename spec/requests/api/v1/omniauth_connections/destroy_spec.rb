# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/omniauth_connections", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:user) do
    u = create(:user, password: "enterprise", password_set_manually: true)
    create(:omniauth_connection, user: u, provider: :discord)
    u
  end
  let(:provider) { "discord" }

  before do
    sign_in(user) if user.present?
  end

  path "/omniauth-connections/{provider}" do
    parameter name: :provider, in: :path, type: :string, required: true

    delete("Disconnect OAuth provider") do
      operationId "disconnectOauthProvider"
      tags "OmniAuth Connections"
      produces "application/json"

      security [{
        SessionCookie: []
      }]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/User"

        run_test! do
          expect(user.reload.omniauth_connections.count).to eq(0)
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end

      response(403, "forbidden - last connection for oauth-only user") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:user, :oauth_only) }

        run_test!
      end
    end
  end
end
