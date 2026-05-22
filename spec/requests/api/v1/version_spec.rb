# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1", type: :openapi, openapi_schema_name: :"v1/schema" do
  path "/version" do
    get("Version of Fleetyards") do
      operationId "version"
      tags "Versions"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/Version"

        run_test!
      end
    end
  end
end
