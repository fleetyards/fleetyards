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

  test "filters by inclusive cargo bounds in SCU" do
    models = [0, 0.5, 32, 64].map { |cargo| create(:model, cargo:, keep_cargo: true) }

    [
      [{cargoGteq: 0.5}, models.drop(1)],
      [{cargoLteq: 0.5}, models.first(2)],
      [{cargoGteq: 0.5, cargoLteq: 32}, models[1..2]],
      [{cargoGteq: 0, cargoLteq: 0}, models.first(1)]
    ].each do |query, expected|
      assert_api_response :get, 200, params: {q: query} do
        assert_equal expected.map(&:id).sort, parsed_body["items"].map { |item| item["id"] }.sort
      end
    end
  end

  test "filters and sorts by the cargo a ship carries with its modules fitted" do
    hull_only = create(:model, cargo: 46, keep_cargo: true)
    modular = create(:model, cargo: 0, keep_cargo: true)
    create(:module_hardpoint, model: modular, slot: "hardpoint_front_module", model_module: create(:model_module, cargo: 38))
    create(:module_hardpoint, model: modular, slot: "hardpoint_rear_module", model_module: create(:model_module, cargo: 36))

    [
      [{cargoGteq: 50}, [modular]],
      [{cargoLteq: 50}, [hull_only]],
      [{withCargo: true}, [hull_only, modular]]
    ].each do |query, expected|
      assert_api_response :get, 200, params: {q: query} do
        assert_equal expected.map(&:id).sort, parsed_body["items"].map { |item| item["id"] }.sort
      end
    end

    assert_api_response :get, 200, params: {q: {sorts: ["cargo desc"]}} do
      assert_equal [modular.id, hull_only.id], parsed_body["items"].map { |item| item["id"] }
      assert_equal [74.0, 46.0], parsed_body["items"].map { |item| item.dig("metrics", "maxCargo") }
    end
  end

  test "sorts by the figures a ship carries as it comes" do
    light = create(:model, name: "Light")
    create(:loadout_stat, fitting: light, max_weapon_size: 1, alpha: 10, burst_dps: 100, sustained_dps_max: 300)
    heavy = create(:model, name: "Heavy")
    create(:loadout_stat, fitting: heavy, max_weapon_size: 3, alpha: 100, burst_dps: 1000, sustained_dps_max: 200)
    concept = create(:model, name: "Concept")

    {
      "maxWeaponSize" => [heavy, light, concept],
      "alpha" => [heavy, light, concept],
      "burstDps" => [heavy, light, concept],
      "sustainedDpsMax" => [light, heavy, concept]
    }.each do |sort, expected|
      assert_api_response :get, 200, params: {q: {sorts: ["#{sort} desc"]}} do
        assert_equal expected.map(&:id), parsed_body["items"].map { |item| item["id"] }
      end
    end
  end

  test "lists the figures a ship carries as it comes" do
    gun = create(:component, component_type: "WeaponGun", category: "weapons", size: "3",
      type_data: {damage_per_shot: {energy: 100}, fire_rate: 600})
    armed = create(:model, production_status: "flight-ready")
    create(:hardpoint, parent: armed, sc_name: "hardpoint_gun_nose", source: :game_files, types: %w[WeaponGun],
      min_size: 3, max_size: 3, component: gun)
    LoadoutStat.refresh
    bare = create(:model)

    assert_api_response :get, 200, params: {q: {sorts: ["alpha desc"]}} do
      first, second = parsed_body["items"]

      assert_equal armed.id, first["id"]
      assert_equal 3, first["maxWeaponSize"]
      assert_equal [{"size" => 3, "count" => 1}], first["weaponSizes"]
      assert_in_delta 100, first["alpha"]
      assert_in_delta 1000, first["burstDps"]
      assert_in_delta 1000, first["sustainedDpsMax"]

      assert_equal bare.id, second["id"]
      assert_nil second["alpha"]
      assert_equal [], second["weaponSizes"]
    end
  end

  test "keeps ships sharing a figure in name order" do
    names = %w[Cutter Avenger Buccaneer]
    names.each { |name| create(:model, name:) }

    assert_api_response :get, 200, params: {q: {sorts: ["alpha desc"]}} do
      assert_equal names.sort, parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "orders ships sharing a name and a figure the same way every time" do
    first, second = 2.times.map { create(:model, name: "Twin", manufacturer: create(:manufacturer)) }.sort_by(&:id)

    assert_api_response :get, 200, params: {q: {sorts: ["alpha desc"]}} do
      assert_equal [first.id, second.id], parsed_body["items"].map { |item| item["id"] }
    end
  end

  test "GET /models returns a list of models" do
    create_list(:model, 6)

    assert_api_response :get, 200 do
      assert_equal 6, parsed_body["items"].count
    end
  end

  test "GET /models leaves the detail-only media to the ship page and carries the lite holos" do
    model = create(:model)
    model.rear_view.attach(io: File.open(Rails.root.join("test/fixtures/files/test.png")), filename: "rear.png")
    model.holo_textured.attach(io: File.open(Rails.root.join("test/fixtures/holo/plain.glb")), filename: "holo_textured.glb")
    model.holo_lite.attach(io: File.open(Rails.root.join("test/fixtures/holo/plain.glb")), filename: "holo_lite.glb")

    assert_api_response :get, 200 do
      media = parsed_body["items"].find { |item| item["slug"] == model.slug }["media"]

      assert_not media.key?("rearView")
      assert_not media.key?("holoTextured")
      assert_equal "holo_lite.glb", media.dig("holoLite", "name")
    end
  end

  test "GET /models filters by nameOrDescriptionCont" do
    models = create_list(:model, 6)

    assert_api_response :get, 200, params: {q: {"nameOrDescriptionCont" => models.first.name}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /models filters by focusIn, matching any of a ship's foci" do
    heavy = create(:model, foci: %w[heavy_fighter])
    hauler = create(:model, foci: %w[freight])
    create(:model, foci: %w[mining])

    assert_api_response :get, 200, params: {q: {"focusIn" => %w[fighter freight]}} do
      assert_equal [heavy.name, hauler.name].sort, parsed_body["items"].map { |item| item["name"] }.sort
    end
  end

  test "GET /models reads a focus worded as before the keys" do
    heavy = create(:model, foci: %w[heavy_fighter])
    create(:model, foci: %w[light_fighter])

    assert_api_response :get, 200, params: {q: {"focusIn" => ["Heavy Fighter"]}} do
      assert_equal [heavy.name], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /models filters by stealthEq and focusIn together" do
    sabre = create(:model, foci: %w[medium_fighter], stealth: true)
    create(:model, foci: %w[bomber], stealth: true)
    create(:model, foci: %w[medium_fighter])

    assert_api_response :get, 200, params: {q: {"stealthEq" => true, "focusIn" => %w[fighter]}} do
      assert_equal [sabre.name], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /models filters by ingameOnlyEq" do
    ingame_only = create(:model, ingame_only: true)
    pledge = create(:model)

    assert_api_response :get, 200, params: {q: {"ingameOnlyEq" => true}} do
      names = parsed_body["items"].map { |item| item["name"] }
      assert_includes names, ingame_only.name
      assert_not_includes names, pledge.name
    end
  end

  test "GET /models filters by playerOwnableEq" do
    ownable = create(:model)
    npc = create(:model, player_ownable: false)

    assert_api_response :get, 200, params: {q: {"playerOwnableEq" => true}} do
      names = parsed_body["items"].map { |item| item["name"] }
      assert_includes names, ownable.name
      assert_not_includes names, npc.name
    end
  end

  test "GET /models narrows to the dearer ships an upgrade can lead into" do
    target = create(:model, pledge_price: 300, ccu_target_seen_at: 1.year.ago, created_at: 2.years.ago)
    create(:model, pledge_price: 900, created_at: 2.years.ago)
    create(:model, pledge_price: 100, ccu_on_sale: true)

    assert_api_response :get, 200, params: {q: {"ccuTarget" => true, "pledgePriceGt" => 200}} do
      assert_equal [target.name], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /models narrows to the ships a plan can get, the user's own among them" do
    user = create(:user)
    priced = create(:model, pledge_price: 300)
    earned = create(:model, pledge_price: nil, ingame_only: true)
    held = create(:model, pledge_price: nil)
    bought_back = create(:model, name: "Galaxy Executive", pledge_price: nil)
    unobtainable = create(:model, pledge_price: nil)
    create(:vehicle, user:, model: held)
    create(:buyback_pledge, user:, name: "Standalone Ship - Galaxy Executive")

    assert_api_response :get, 200, params: {q: {"plannable" => true}} do
      names = parsed_body["items"].map { |item| item["name"] }
      assert_includes names, priced.name
      assert_includes names, earned.name
      assert_not_includes names, held.name
    end

    sign_in user

    assert_api_response :get, 200, params: {q: {"plannable" => true}} do
      names = parsed_body["items"].map { |item| item["name"] }
      assert_includes names, held.name
      assert_includes names, bought_back.name
      assert_not_includes names, unobtainable.name
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
  # The filter and the detail page answer from the same berths, so a module's
  # lift has to count here too or the two disagree again.
  test "GET /models counts a module's berth for willItFit" do
    carrier = create(:model, slug: "modular-carrier")
    model_module = create(:model_module)
    create(:module_hardpoint, model: carrier, model_module: model_module)
    create(:dock, :with_dimensions, parent: model_module, dock_type: :hangar)

    fits = create(:model, length: 20.0, beam: 10.0, height: 5.0)
    too_big = create(:model, length: 300.0, beam: 100.0, height: 60.0)

    assert_api_response :get, 200, params: {q: {willItFit: carrier.slug}} do
      slugs = parsed_body["items"].map { |item| item["slug"] }

      assert_includes slugs, fits.slug
      assert_not_includes slugs, too_big.slug
    end
  end

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

  test "GET /models answers perPage=all with every model, since it offers all" do
    create_list(:model, Model.default_per_page + 1)

    assert_api_response :get, 200, params: {perPage: "all"} do
      assert_equal Model.default_per_page + 1, parsed_body["items"].count
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
