# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/models", type: :openapi, openapi_schema_name: :"v1/schema" do
  let!(:models) { create_list(:model, 6) }

  path "/models/slugs" do
    get("Available Model-Slugs") do
      operationId "modelsSlugs"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        run_test!
      end
    end
  end
end
