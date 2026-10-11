# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsHardpointsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/hardpoints" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Hardpoints") do
      operationId "modelHardpoints"
      tags "Models"
      produces "application/json"

      parameter name: "source", in: :query,
        schema: ::Shared::V1::Schemas::Enums::HardpointSourceEnum, required: false

      response(200, "successful") do
        schema ::V1::Schemas::Models::Hardpoints::HardpointsList
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /models/:slug/hardpoints returns hardpoints" do
    model = create(:model, :with_hardpoints)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal model.hardpoints.size, parsed_body.count
    end
  end

  test "GET /models/:slug/hardpoints returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end

  # The facts come from the build row now, not from the slot's own columns. The
  # two are dual-written and normally agree, so the only way to show which one
  # is being read is to make them disagree.
  test "GET /models/:slug/hardpoints reads what the build says, not the column" do
    model = create(:model)
    column_component = create(:component, name: "What The Column Says")
    build_component = create(:component, name: "What The Build Says")

    hardpoint = create(:hardpoint, :without_build, parent: model, sc_name: "hardpoint_power",
      source: :game_files, component: column_component, min_size: 1, max_size: 1)
    create(:hardpoint_build, hardpoint:, component: build_component, min_size: 4, max_size: 4)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      entry = parsed_body.sole

      assert_equal "What The Build Says", entry.dig("component", "name")
      assert_equal 4, entry["minSize"]
      assert_equal 4, entry["maxSize"]
    end
  end

  # A slot the build does not describe stops being offered. It keeps its row --
  # once the cleanup stops destroying, that is what makes a retired port
  # survivable -- but it is not part of this ship's loadout any more.
  test "GET /models/:slug/hardpoints leaves out a slot no build describes" do
    model = create(:model)
    create(:hardpoint, parent: model, sc_name: "in_this_build", source: :game_files)
    create(:hardpoint, :without_build, parent: model, sc_name: "retired", source: :game_files)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal ["in_this_build"], parsed_body.map { |entry| entry["name"] }
    end
  end

  # The matrix half comes from no build and has no build row to find, so it must
  # not be filtered out by the same rule.
  test "GET /models/:slug/hardpoints still offers the ship-matrix slots" do
    model = create(:model)
    create(:hardpoint, parent: model, sc_name: "curated", source: :ship_matrix)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal ["curated"], parsed_body.map { |entry| entry["name"] }
    end
  end

  test "GET /models/:slug/hardpoints leaves a retired child out of the nesting" do
    model = create(:model)
    parent = create(:hardpoint, parent: model, sc_name: "turret", source: :game_files)
    create(:hardpoint, parent:, sc_name: "kept_gun", source: :game_files)
    create(:hardpoint, :without_build, parent:, sc_name: "retired_gun", source: :game_files)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      nested = parsed_body.sole["hardpoints"]

      assert_equal ["kept_gun"], nested.map { |entry| entry["name"] }
    end
  end

  # A turret's guns sit a slot below the hardpoint the fragment is keyed on, and
  # a price sync touches neither the slot nor the gun.
  test "GET /models/:slug/hardpoints serves a nested component's new price after the payload was cached" do
    model = create(:model)
    turret = create(:hardpoint, parent: model, sc_name: "hardpoint_turret", source: :game_files)
    gun = create(:component, name: "Turret Gun")
    create(:hardpoint, parent: turret, sc_name: "hardpoint_gun", source: :game_files, component: gun)
    price = create(:item_price, item: gun, price_type: :sell, price: 100, location: "Admin - Area18")

    with_fragment_caching do
      get "/api/v1/models/#{model.slug}/hardpoints"
      assert_equal [100.0], sold_at_prices(response.parsed_body)

      ItemPrice.where(id: price.id).update_all(price: 120, updated_at: 1.minute.from_now)
      get "/api/v1/models/#{model.slug}/hardpoints"

      assert_equal [120.0], sold_at_prices(response.parsed_body)
    end
  end

  test "GET /models/:slug/hardpoints labels a component in the caller's locale after another locale cached it" do
    model = create(:model)
    cooler = create(:component, name: "Cooler", item_class: "industrial")
    create(:hardpoint, parent: model, sc_name: "hardpoint_cooler", source: :game_files, component: cooler)

    with_fragment_caching do
      get "/api/v1/models/#{model.slug}/hardpoints", headers: {"Accept-Language" => "zh-CN"}
      assert_equal "工业", response.parsed_body.sole.dig("component", "itemClassLabel")

      get "/api/v1/models/#{model.slug}/hardpoints", headers: {"Accept-Language" => "en"}

      assert_equal "Industrial", response.parsed_body.sole.dig("component", "itemClassLabel")
    end
  end

  private def sold_at_prices(body)
    body.sole["hardpoints"].sole.dig("component", "availability", "soldAt").map { |entry| entry["price"] }
  end
end
