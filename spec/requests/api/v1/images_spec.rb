# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/images", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :images

  before do
    host! "api.fleetyards.test"
  end

  path "/images" do
    get("list images") do
      description "Get a List of Images"
      tags "Images"
      produces "application/json"

      response(200, "successful") do
        schema type: :array,
          items: {"$ref" => "#/components/schemas/Image"}

        run_test!
      end
    end
  end

  path "/images/random" do
    get("random image") do
      description "Get a randomized List of Images"
      tags "Images"
      produces "application/json"

      response(200, "successful") do
        schema type: :array,
          items: {"$ref" => "#/components/schemas/Image"}

        run_test!
      end
    end
  end
end
