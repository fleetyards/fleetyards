# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models" do
    get("Models List") do
      operationId "models"
      tags "Models"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Model.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::ModelQuery,
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "containerFit", in: :query,
        schema: ::V1::Schemas::Queries::ContainerFitQuery,
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema ::V1::Schemas::Models::Models
      end
    end
  end

  test "GET /models returns a list of models" do
    create_list(:model, 6)

    assert_api_response :get, 200 do
      assert_equal 6, parsed_body["items"].count
    end
  end

  test "GET /models filters by nameOrDescriptionCont" do
    models = create_list(:model, 6)

    assert_api_response :get, 200, params: {q: {"nameOrDescriptionCont" => models.first.name}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /models accepts a containerFit map" do
    create_list(:model, 2)

    assert_api_response :get, 200, params: {containerFit: {"16" => 2, "32" => 1}}
  end

  # Plain get rather than the DSL: declaring a 400 here would replace the
  # auto-injected SchemaValidationError response and move the schema.
  test "GET /models rejects a containerFit size outside the standard set" do
    get "/api/v1/models", params: {containerFit: {"7" => 1}}

    assert_response :bad_request
  end

  # `page` and `per_page` were handed straight to kaminari, which calls `to_i`
  # on them -- so a query string that made either a hash or an array was a 500.
  # Same treatment as `?page=abc`: the value is dropped and the first page is
  # served. Covers 19 controllers through the Pagination concern.
  [
    ["a nested page", {page: {"x" => 1}}],
    ["an array page", {page: [1]}],
    ["a nested per_page", {per_page: {"x" => 1}}],
    ["an array per_page", {per_page: [1]}]
  ].each do |label, params|
    test "GET /models serves the first page given #{label}" do
      create(:model)

      get "/api/v1/models", params: params

      assert_response :success
      assert_equal 1, parsed_body["items"].count
    end
  end

  # The picker sends a slug and the controller resolves one, but the schema asked
  # for a uuid — so every real request was rejected before reaching the action.
  test "GET /models accepts a slug for willItFit" do
    carrier = create(:model, slug: "fitting-carrier")
    create(:dock, :with_dimensions, parent: carrier, dock_type: :hangar)

    fits = create(:model, length: 20.0, beam: 10.0, height: 5.0)
    too_big = create(:model, length: 300.0, beam: 100.0, height: 60.0)

    assert_api_response :get, 200, params: {q: {willItFit: carrier.slug}} do
      slugs = parsed_body["items"].map { |item| item["slug"] }

      assert_includes slugs, fits.slug
      assert_not_includes slugs, too_big.slug
    end
  end

  # An unmeasured dock used to become half a metre, so a carrier nobody measured
  # answered "nothing fits" rather than declining to answer.
  test "GET /models does not empty the list for a carrier with unmeasured docks" do
    carrier = create(:model, slug: "unmeasured-carrier")
    create(:dock, parent: carrier, dock_type: :hangar)
    other = create(:model, length: 20.0, beam: 10.0, height: 5.0)

    assert_api_response :get, 200, params: {q: {willItFit: carrier.slug}} do
      slugs = parsed_body["items"].map { |item| item["slug"] }

      assert_includes slugs, other.slug
    end
  end

  test "GET /models honours perPage" do
    create_list(:model, 6)

    assert_api_response :get, 200, params: {perPage: 2} do
      assert_equal 2, parsed_body["items"].count
    end
  end

  # The logo and the icon hang off the manufacturer, so neither one moves the
  # model's own `updated_at` -- the cache key has to name the manufacturer or the
  # list keeps serving the picture the first request happened to render.
  test "GET /models serves a manufacturer logo replaced after the payload was cached" do
    manufacturer = create(:manufacturer, :with_logo)
    create(:model, manufacturer:)

    with_fragment_caching do
      get "/api/v1/models"
      cached_url = response.parsed_body["items"].first.dig("manufacturer", "logo", "url")

      manufacturer.logo.attach(
        Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/image.jpg"), "image/jpeg")
      )

      get "/api/v1/models"

      assert_not_equal cached_url, response.parsed_body["items"].first.dig("manufacturer", "logo", "url")
    end
  end

  test "GET /models serves a manufacturer icon replaced after the payload was cached" do
    manufacturer = create(:manufacturer, :with_icon)
    create(:model, manufacturer:)

    with_fragment_caching do
      get "/api/v1/models"
      cached_url = response.parsed_body["items"].first.dig("manufacturer", "icon", "url")

      manufacturer.icon.attach(
        Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/image.jpg"), "image/jpeg")
      )

      get "/api/v1/models"

      assert_not_equal cached_url, response.parsed_body["items"].first.dig("manufacturer", "icon", "url")
    end
  end
end
