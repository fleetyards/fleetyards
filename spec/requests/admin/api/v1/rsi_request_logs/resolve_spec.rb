# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/rsi_request_logs", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:"rsi-api-status"]) }
  let(:rsi_request_log) { RsiRequestLog.create!(url: "https://robertsspaceindustries.com/test") }
  let(:id) { rsi_request_log.id }

  before do
    sign_in user if user.present?
  end

  path "/rsi-request-logs/{id}/resolve" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "RSI Request Log id", required: true

    put("Resolve RSI Request Log") do
      operationId "resolveRsiRequestLog"
      tags "RsiRequestLogs"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/RsiRequestLog"
        run_test!
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
