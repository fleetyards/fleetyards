# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/rsi_request_logs", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:"rsi-api-status"]) }

  before do
    sign_in user if user.present?
  end

  path "/rsi-request-logs" do
    get("RSI Request Logs list") do
      operationId "rsiRequestLogs"
      tags "RsiRequestLogs"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: RsiRequestLog.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "cacheId", in: :query, type: :string, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/RsiRequestLogs"

        before do
          RsiRequestLog.create!(url: "https://robertsspaceindustries.com/test")
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"].count).to eq(1)
        end
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
        let(:user) { create(:admin_user, resource_access: []) }
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
