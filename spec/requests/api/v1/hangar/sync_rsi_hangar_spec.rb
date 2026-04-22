# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/hangar", type: :openapi, openapi_schema_name: :"v1/schema" do
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
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarSyncSubmitResult"

        run_test!
      end

      include_examples "oauth_auth"

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:input) { nil }

        run_test!
      end
    end
  end
end
