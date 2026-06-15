# frozen_string_literal: true

require "openapi_helper"

class Api::V1::CompareShareTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/compare/share" do
    post("Create a short share URL for a comparison") do
      operationId "compareShare"
      tags "Compare"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/CompareShareInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/CompareShare"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @carrack = create_model_with_slug("anvil-carrack")
    @cutlass = create_model_with_slug("drake-cutlass-black")
    Rails.configuration.app.stubs(:short_domain).returns("fltyrd.test")
  end

  test "POST /compare/share returns short and long URLs and persists a CompareImage" do
    assert_api_response :post, 200, body: {models: [@carrack.slug, @cutlass.slug]} do
      assert_match(%r{://fltyrd\.test/c/[A-Za-z0-9]{8}\z}, parsed_body["shortUrl"])
      assert_includes parsed_body["longUrl"], "/compare"
      assert_includes parsed_body["longUrl"], "anvil-carrack"
      assert_includes parsed_body["longUrl"], "drake-cutlass-black"
    end

    record = CompareImage.find_by(share_key: "anvil-carrack,drake-cutlass-black")
    assert record.present?
    assert_match(/\A[A-Za-z0-9]{8}\z/, record.short_code)
  end

  test "POST /compare/share returns the same short_url for the same comparison" do
    assert_api_response :post, 200, body: {models: [@carrack.slug, @cutlass.slug]}
    first = parsed_body["shortUrl"]

    assert_api_response :post, 200, body: {models: [@cutlass.slug, @carrack.slug]}
    second = parsed_body["shortUrl"]

    assert_equal first, second
  end

  test "POST /compare/share returns 400 with no models supplied" do
    assert_api_response :post, 400, body: {models: []}
  end

  test "POST /compare/share returns 400 with too many models" do
    too_many = (1..(CompareImage::MAX_SHARE_MODELS + 1)).map { |i| "extra-#{i}" }
    assert_api_response :post, 400, body: {models: too_many}
  end

  test "POST /compare/share returns 400 with only unknown slugs" do
    assert_api_response :post, 400, body: {models: ["does-not-exist"]}
  end

  private

  def create_model_with_slug(slug)
    model = create(:model)
    model.update_columns(slug: slug)
    model
  end
end
