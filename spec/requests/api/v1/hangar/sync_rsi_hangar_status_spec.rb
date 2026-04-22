# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/hangar", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:author) { create(:user) }
  let(:user) { author }

  let(:Authorization) { nil }

  before do
    sign_in(user) if user.present?
  end

  path "/hangar/sync-rsi-hangar/status" do
    get("Sync RSI Hangar Status") do
      operationId "syncRsiHangarStatus"
      tags "Hangar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarSyncStatus"

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
