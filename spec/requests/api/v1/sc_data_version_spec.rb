# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1", type: :request, swagger_doc: "v1/schema.yaml" do
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
