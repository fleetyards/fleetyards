# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user) }
  let(:input) do
    {
      items: [{
        id: "1",
        name: "Constellation Andromeda",
        type: "ship"
      }]
    }
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

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarSyncResult"

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
