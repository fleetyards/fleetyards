# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ImagesIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/images" do
    get("Images list") do
      operationId "images"
      tags "Images"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Image.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ImageQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Images"
      end
    end
  end

  test "GET /images lists images" do
    create_list(:image, 5)

    assert_api_response :get, 200 do
      assert_equal 5, parsed_body["items"].count
    end
  end

  test "GET /images filters by modelIn query" do
    create_list(:image, 4, gallery: create(:model))
    target = create(:image, gallery: create(:model))

    assert_api_response :get, 200, params: {q: {"modelIn" => [target.gallery.slug]}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /images paginates with perPage" do
    create_list(:image, 5)

    assert_api_response :get, 200, params: {perPage: 1} do
      assert_equal 1, parsed_body["items"].count
    end
  end
end
