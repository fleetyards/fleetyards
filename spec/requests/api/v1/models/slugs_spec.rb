# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/models", type: :request, swagger_doc: "v1/schema.yaml" do
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
