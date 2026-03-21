# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:input) do
    {
      items: [{
        id: "1",
        name: "Constellation Andromeda",
        type: "ship"
      }]
    }
  end

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["hangar", "hangar:write"]
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

  path "/hangar/sync-rsi-hangar" do
    put("Sync RSI Hangar") do
      operationId "syncRsiHangar"
      tags "Hangar"
      consumes "application/json"
      produces "application/json"

      parameter name: :input,
        in: :body,
        schema: {"$ref": "#/components/schemas/SyncRsiHangarInput"},
        required: true

      security [
        { SessionCookie: [] },
        { Oauth2: ["hangar", "hangar:write"] },
        { OpenId: ["hangar", "hangar:write"] }
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarSyncResult"

        run_test!
      end

      response(200, "successful with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }

        run_test!
      end

      response(401, "unauthorized with wrong scope token") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:Authorization) { "Bearer #{wrong_scope_access_token.token}" }

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:input) { nil }

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
