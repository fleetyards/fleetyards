# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/equipment", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :equipment

  before do
    host! "api.fleetyards.test"
  end

  path "/equipment" do
    get("list equipment") do
      description "Get a List of Equipment"
      tags "Equipment"
      produces "application/json"

      response(200, "successful") do
        schema type: :array,
          items: {"$ref" => "#/components/schemas/Equipment"}

        run_test!
      end
    end
  end
end
