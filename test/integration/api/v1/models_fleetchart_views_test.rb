# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsFleetchartViewsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/fleetchart-views" do
    get("Ship views for a fleetchart") do
      operationId "modelsFleetchartViews"
      tags "Models"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::FleetchartViewQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::V1::Schemas::Models::FleetchartViewsList
      end
    end
  end

  test "GET /models/fleetchart-views returns the views for the requested slugs" do
    wanted = create(:model)
    create(:model)

    assert_api_response :get, 200, params: {q: {slugIn: [wanted.slug]}}

    assert_equal [wanted.slug], response.parsed_body.map { |entry| entry["slug"] }
  end

  # Nothing to draw rather than the whole catalogue, which is what a missing
  # filter would otherwise mean.
  test "GET /models/fleetchart-views without slugs returns nothing" do
    create(:model)

    get "/api/v1/models/fleetchart-views"

    assert_response :success
    assert_empty response.parsed_body
  end

  # A hangar may hold a ship the catalogue hides, and its chart still has to draw
  # it -- so this lookup does not apply the visible and active scopes the list does.
  test "GET /models/fleetchart-views serves a hidden model" do
    hidden = create(:model, hidden: true)

    get "/api/v1/models/fleetchart-views", params: {q: {slugIn: [hidden.slug]}}

    assert_response :success
    assert_equal [hidden.slug], response.parsed_body.map { |entry| entry["slug"] }
  end

  test "GET /models/fleetchart-views serves the rear views" do
    model = create(:model)
    png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")

    model.rear_view.attach(io: StringIO.new(png), filename: "rear.png", content_type: "image/png")

    get "/api/v1/models/fleetchart-views", params: {q: {slugIn: [model.slug]}}

    assert_response :success
    assert response.parsed_body.first.dig("media", "rearView", "url").present?
  end

  test "GET /models can ask for only the ships a fleetchart can draw" do
    png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")
    drawable = create(:model)
    only_rear = create(:model)
    create(:model)

    drawable.port_view.attach(io: StringIO.new(png), filename: "port.png", content_type: "image/png")
    only_rear.rear_view.attach(io: StringIO.new(png), filename: "rear.png", content_type: "image/png")

    get "/api/v1/models", params: {q: {hasFleetchartViews: true}}

    assert_response :success
    assert_equal [drawable.id], response.parsed_body["items"].map { |model| model["id"] }
  end

  test "GET /models/fleetchart-views caps how many slugs it answers" do
    models = create_list(:model, 3)

    get "/api/v1/models/fleetchart-views",
      params: {q: {slugIn: models.map(&:slug) + ["nope"]}}

    assert_response :success
    assert_equal models.map(&:slug).sort, response.parsed_body.map { |entry| entry["slug"] }.sort
  end
end
