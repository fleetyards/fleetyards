# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ImagesRandomTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/images/random" do
    get("Images random list") do
      operationId "imagesRandom"
      description "Get a randomized List of 14 Images"
      tags "Images"
      produces "application/json"

      parameter name: "limit", in: :query, schema: {
        type: :number,
        minimum: 1,
        maximum: Image.default_per_page,
        default: 14
      }, required: false

      response(200, "successful") do
        schema type: :array,
          items: {"$ref" => "#/components/schemas/Image"}
      end
    end
  end

  test "GET /images/random returns 14 images by default" do
    create_list(:image, 20)

    assert_api_response :get, 200 do
      assert_equal 14, parsed_body.count
    end
  end

  test "GET /images/random honors limit parameter" do
    create_list(:image, 20)

    assert_api_response :get, 200, params: {limit: 1} do
      assert_equal 1, parsed_body.count
    end
  end
end
