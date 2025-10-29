# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1", type: :request, swagger_doc: "v1/schema.yaml" do
  before do
    Flipper.enable("NewFeature")
  end

  path "/features" do
    get("Feature Flags for User") do
      operationId "features"
      tags "Features"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {type: :string}

        run_test! do |response|
          expect(JSON.parse(response.body)).to eq(["NewFeature"])
        end
      end
    end
  end
end
