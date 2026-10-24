# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsModulesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/modules" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Modules") do
      operationId "modelModules"
      tags "Models"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelModule.default_per_page}, required: false

      response(200, "successful") do
        schema ::V1::Schemas::Models::Modules::ModelModules
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /models/:slug/modules returns modules" do
    model = create(:model, :with_modules)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal model.modules.count, parsed_body["items"].count
      assert_operator parsed_body["items"].count, :>, 0
    end
  end

  test "GET /models/:slug/modules serves the medical beds a module holds" do
    model = create(:model)
    medical = create(:model_module, name: "Tier 2 Module",
      medical_beds: {"tiers" => [{"tier" => 2, "name" => "Clinic", "beds" => 2}], "respawn_beds" => 2})
    create(:module_hardpoint, model:, model_module: medical)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal(
        {"tiers" => [{"tier" => 2, "name" => "Clinic", "beds" => 2}], "respawnBeds" => 2},
        parsed_body["items"].sole.dig("metrics", "medicalBeds")
      )
    end
  end

  test "GET /models/:slug/modules says which parts in its ports a recipe makes, all the way down" do
    model = create(:model)
    combat = create(:model_module, name: "Combat Module")
    create(:module_hardpoint, model:, model_module: combat)

    shield = create(:component, component_type: "Shield", category: "shieldgenerator", size: "2")
    turret = create(:component, component_type: "Turret", category: "turret", size: "3")
    gun = create(:component, component_type: "WeaponGun", category: "weapons", size: "3")
    create(:hardpoint, parent: combat, sc_name: "hardpoint_shield", source: :game_files, component: shield)
    create(:hardpoint, parent: combat, sc_name: "hardpoint_turret", source: :game_files, component: turret)
    create(:hardpoint, parent: turret, sc_name: "hardpoint_gun", source: :game_files, component: gun)
    create(:blueprint, craftable: shield)
    create(:blueprint, craftable: gun)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal [gun.id, shield.id].sort, parsed_body["craftableComponentIds"].sort
    end
  end

  test "GET /models/:slug/modules serialises the slot when set on module_hardpoint" do
    model = create(:model)
    create(:module_hardpoint, model: model, slot: "hardpoint_front_module")

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal "hardpoint_front_module", parsed_body["items"].first["slot"]
    end
  end

  test "GET /models/:slug/modules marks the module the hull comes with" do
    model = create(:model)
    stock = create(:model_module, name: "Stock Module", sc_key: "RSI_Stock_Module")
    extra = create(:model_module, name: "Extra Module", sc_key: "RSI_Extra_Module")
    create(:module_hardpoint, model:, model_module: stock, slot: "hardpoint_module")
    create(:module_hardpoint, model:, model_module: extra, slot: "hardpoint_module")
    create(:hardpoint, parent: model, source: :game_files, sc_name: "hardpoint_module",
      component: create(:component, sc_key: "rsi_stock_module", category: "module", component_type: "Module"))

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal({"Extra Module" => false, "Stock Module" => true},
        parsed_body["items"].to_h { |item| [item["name"], item["stock"]] })
    end
  end

  test "GET /models/:slug/modules returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end

  # The logo hangs off the manufacturer, so it moves nothing the module's own
  # cache key names -- see Manufacturer.artwork_version.
  test "GET /models/:slug/modules serves a manufacturer logo replaced after the payload was cached" do
    manufacturer = create(:manufacturer, :with_logo)
    model = create(:model)
    create(:module_hardpoint, model:, model_module: create(:model_module, manufacturer:))

    with_fragment_caching do
      get "/api/v1/models/#{model.slug}/modules"
      cached_url = response.parsed_body["items"].first.dig("manufacturer", "logo", "url")

      manufacturer.logo.attach(
        Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/image.jpg"), "image/jpeg")
      )

      get "/api/v1/models/#{model.slug}/modules"

      assert_not_equal cached_url, response.parsed_body["items"].first.dig("manufacturer", "logo", "url")
    end
  end

  # A price sync touches neither the module, its slots nor the component.
  test "GET /models/:slug/modules serves a component's new price after the payload was cached" do
    model = create(:model)
    model_module = create(:model_module)
    create(:module_hardpoint, model:, model_module:)
    gun = create(:component, name: "Module Gun")
    create(:hardpoint, parent: model_module, sc_name: "hardpoint_gun", source: :game_files, component: gun)
    price = create(:item_price, item: gun, price_type: :sell, price: 100, location: "Admin - Area18")

    with_fragment_caching do
      get "/api/v1/models/#{model.slug}/modules"
      assert_equal [100.0], sold_at_prices(response.parsed_body)

      ItemPrice.where(id: price.id).update_all(price: 120, updated_at: 1.minute.from_now)
      get "/api/v1/models/#{model.slug}/modules"

      assert_equal [120.0], sold_at_prices(response.parsed_body)
    end
  end

  # A render lands on the component alone, which nothing in the module's key names.
  test "GET /models/:slug/modules serves a component's angled view attached after the payload was cached" do
    model = create(:model)
    model_module = create(:model_module)
    create(:module_hardpoint, model:, model_module:)
    gun = create(:component, name: "Module Gun")
    create(:hardpoint, parent: model_module, sc_name: "hardpoint_gun", source: :game_files, component: gun)

    with_fragment_caching do
      get "/api/v1/models/#{model.slug}/modules"
      assert_nil response.parsed_body["items"].sole["hardpoints"].sole.dig("component", "media", "storeImage")

      travel 1.minute do
        gun.angled_view.attach(io: file_fixture("test.png").open, filename: "angled.png", content_type: "image/png")
      end
      get "/api/v1/models/#{model.slug}/modules"

      assert_equal "angled.png",
        response.parsed_body["items"].sole["hardpoints"].sole.dig("component", "media", "storeImage", "name")
    end
  end

  test "GET /models/:slug/modules labels a component in the caller's locale after another locale cached it" do
    model = create(:model)
    model_module = create(:model_module)
    create(:module_hardpoint, model:, model_module:)
    cooler = create(:component, name: "Module Cooler", item_class: "industrial")
    create(:hardpoint, parent: model_module, sc_name: "hardpoint_cooler", source: :game_files, component: cooler)

    with_fragment_caching do
      get "/api/v1/models/#{model.slug}/modules", headers: {"Accept-Language" => "zh-CN"}
      assert_equal "工业", item_class_label(response.parsed_body)

      get "/api/v1/models/#{model.slug}/modules", headers: {"Accept-Language" => "en"}

      assert_equal "Industrial", item_class_label(response.parsed_body)
    end
  end

  test "GET /models/:slug/modules serves the module's own new price after the payload was cached" do
    model = create(:model)
    model_module = create(:model_module)
    create(:module_hardpoint, model:, model_module:)
    price = create(:item_price, item: model_module, price_type: :sell, price: 100, location: "Admin - Area18")

    with_fragment_caching do
      get "/api/v1/models/#{model.slug}/modules"
      assert_equal [100.0], module_sold_at_prices(response.parsed_body)

      ItemPrice.where(id: price.id).update_all(price: 120, updated_at: 1.minute.from_now)
      get "/api/v1/models/#{model.slug}/modules"

      assert_equal [120.0], module_sold_at_prices(response.parsed_body)
    end
  end

  private def sold_at_prices(body)
    body["items"].sole["hardpoints"].sole.dig("component", "availability", "soldAt").map { |entry| entry["price"] }
  end

  private def item_class_label(body)
    body["items"].sole["hardpoints"].sole.dig("component", "itemClassLabel")
  end

  private def module_sold_at_prices(body)
    body["items"].sole.dig("availability", "soldAt").map { |entry| entry["price"] }
  end
end
