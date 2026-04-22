# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/models", type: :openapi, openapi_schema_name: :"v1/schema" do
  path "/models/updated" do
    get("Updated Models") do
      operationId "modelsUpdated"
      tags "Models"
      produces "application/json"

      parameter name: :from, in: :query, schema: {type: :string, format: :datetime}, required: false
      parameter name: :to, in: :query, schema: {type: :string, default: :now, format: :datetime}, required: false

      response(200, "successful") do
        let(:from) { 1.day.ago }

        run_test!
      end

      response(304, "not modified") do
        run_test!
      end
    end
  end
end
