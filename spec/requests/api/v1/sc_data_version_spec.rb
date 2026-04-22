# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:import) { create(:import, :scdata_all, aasm_state: :finished, version: "1.0.0") }

  before do
    import
  end

  path "/sc-data/version" do
    get("SC Data Version") do
      operationId "scDataVersion"
      tags "Versions"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/ScDataVersion"

        run_test!
      end
    end
  end
end
