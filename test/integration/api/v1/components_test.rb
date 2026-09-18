# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ComponentsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/components" do
    get("Components list") do
      operationId "components"
      tags "Components"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Component.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::ComponentQuery,
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema ::Shared::V1::Schemas::Components
      end
    end
  end

  setup do
    @components = create_list(:component, 2)
  end

  test "GET /components lists all components" do
    assert_api_response :get, 200 do
      assert_equal 2, parsed_body.count
    end
  end

  test "GET /components filters by nameCont query" do
    assert_api_response :get, 200, params: {q: {"nameCont" => @components.first.name}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal @components.first.name, items.first["name"]
    end
  end

  test "GET /components paginates with perPage" do
    assert_api_response :get, 200, params: {perPage: 2} do
      assert_equal 2, parsed_body.count
    end
  end

  test "GET /components filters by categoryIn query" do
    shield = create(:component, category: "shieldgenerator")
    create(:component, category: "cooler")

    assert_api_response :get, 200, params: {q: {"categoryIn" => ["shieldgenerator"]}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal shield.name, items.first["name"]
    end
  end

  test "GET /components filters by componentSubTypeIn query" do
    missile = create(:component, category: "weapons", component_sub_type: "Missile")
    create(:component, category: "weapons", component_sub_type: "Gun")

    assert_api_response :get, 200, params: {q: {"componentSubTypeIn" => ["Missile"]}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal missile.name, items.first["name"]
    end
  end

  test "GET /components filters by hiddenEq query" do
    visible = create(:component, category: "coolers")
    create(:component, :hidden, category: "coolers")

    assert_api_response :get, 200, params: {q: {"hiddenEq" => false, "categoryIn" => ["coolers"]}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal visible.name, items.first["name"]
    end
  end

  # Asserted by membership rather than by count: the factory gives every
  # component the current version now -- it has to, since the catalogue filter is
  # an inner join to the build -- so the two from `setup` are current as well and
  # a count would be measuring them too.
  test "GET /components filters out older game versions via currentVersion" do
    current = create(:component, category: "coolers", version: ScData::Source.version)
    older = create(:component, category: "coolers", version: "0.0.1-live.1")

    assert_api_response :get, 200, params: {q: {"currentVersion" => true}} do
      names = parsed_body["items"].map { |item| item["name"] }

      assert_includes names, current.name
      assert_not_includes names, older.name
    end
  end

  test "GET /components keeps older game versions when currentVersion is off" do
    older = create(:component, category: "coolers", version: "0.0.1-live.1")

    assert_api_response :get, 200, params: {q: {"currentVersion" => false}} do
      names = parsed_body["items"].map { |item| item["name"] }

      assert_includes names, older.name
    end
  end

  # The logo hangs off the manufacturer, so it moves nothing the component's own
  # cache key names -- see Manufacturer.artwork_version.
  test "GET /components serves a manufacturer logo replaced after the payload was cached" do
    manufacturer = create(:manufacturer, :with_logo)
    component = create(:component, manufacturer:)

    with_fragment_caching do
      get "/api/v1/components", params: {q: {"nameCont" => component.name}}
      cached_url = response.parsed_body["items"].first.dig("manufacturer", "logo", "url")

      manufacturer.logo.attach(
        Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/image.jpg"), "image/jpeg")
      )

      get "/api/v1/components", params: {q: {"nameCont" => component.name}}

      assert_not_equal cached_url, response.parsed_body["items"].first.dig("manufacturer", "logo", "url")
    end
  end
  # The index overwrote whatever sort arrived with "name asc" until this
  # branch, so none of the paths below had ever run.
  test "GET /components sorts by name, both directions" do
    create(:component, name: "Zeus Cannon")
    create(:component, name: "Alpha Cannon")

    assert_api_response :get, 200, params: {q: {"sorts" => ["name desc"]}} do
      names = parsed_body["items"].map { |item| item["name"] }
      assert_equal names.sort.reverse, names
    end
  end

  # `q[s]` is what a sortable list actually sends; ransack reads it directly, so
  # a leftover would outrank the whitelisted `sorts`.
  test "GET /components accepts the s parameter as well as sorts" do
    create(:component, name: "Zeus Cannon")
    create(:component, name: "Alpha Cannon")

    assert_api_response :get, 200, params: {q: {"s" => "name desc"}} do
      names = parsed_body["items"].map { |item| item["name"] }
      assert_equal names.sort.reverse, names
    end
  end

  # The point of moving `type_data` to jsonb: a figure inside it can order the
  # whole result set, not one page of it.
  test "GET /components sorts on a metric inside typeData" do
    create(:component, name: "Weak Shield", type_data: {"max_health" => 100})
    create(:component, name: "Strong Shield", type_data: {"max_health" => 9000})

    assert_api_response :get, 200, params: {q: {"sorts" => ["maxHealth desc"], "nameCont" => "Shield"}} do
      assert_equal ["Strong Shield", "Weak Shield"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  # Numerically, which is the whole reason `sizeOrder` exists as a name of its
  # own: `size` is a string ransacker, so ordering on it puts 10 and 12 ahead
  # of 2.
  test "GET /components sorts by size numerically" do
    ["2", "10", "1"].each_with_index do |size, index|
      create(:component, name: "Size #{size}", size:, sc_key: "size_sort_#{index}")
    end

    assert_api_response :get, 200, params: {q: {"sorts" => ["sizeOrder asc"], "nameCont" => "Size "}} do
      assert_equal ["Size 1", "Size 2", "Size 10"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  # Each of these is dropped without a word if it is missing from
  # `ransackable_attributes` -- the sort simply does not appear in the SQL, and
  # the column comes back in whatever order the planner chose. `sizeOrder` was
  # exactly that until it was listed.
  #
  # Asserted as "descending is ascending reversed" rather than against a fixed
  # list: it needs no expected order written out per field, and a dropped sort
  # returns the same order both ways, which is exactly what it catches. A status
  # check alone would pass for every one of them.
  test "GET /components applies every sort the table offers" do
    [
      {name: "Sortprobe Aardvark", grade: "A", category: "cooler", component_sub_type: "Alpha", size: "1"},
      {name: "Sortprobe Basilisk", grade: "B", category: "powerplant", component_sub_type: "Beta", size: "2"},
      {name: "Sortprobe Cormorant", grade: "C", category: "radar", component_sub_type: "Gamma", size: "10"}
    ].each_with_index do |attrs, index|
      create(:component, sc_key: "sort_probe_#{index}",
        manufacturer: create(:manufacturer, name: "Maker #{attrs[:grade]}"), **attrs)
    end

    %w[name grade category componentSubType manufacturerName sizeOrder].each do |field|
      ascending = nil

      %w[asc desc].each do |direction|
        assert_api_response :get, 200, params: {
          # Scoped to the three probes: every other component in the set ties
          # on these fields, and ties do not reverse, so an unscoped comparison
          # would fail for a sort that works perfectly well.
          q: {"sorts" => ["#{field} #{direction}"], "nameCont" => "Sortprobe"}
        } do
          names = parsed_body["items"].map { |item| item["name"] }

          if direction == "asc"
            ascending = names
          else
            assert_equal ascending.reverse, names,
              "#{field} came back in the same order both ways, so the sort was dropped"
          end
        end
      end
    end
  end

  # The sort list is an enum in the schema, so a value outside it is refused at
  # the door with a 400 naming what is allowed -- rather than reaching ransack,
  # which would raise on an unknown attribute, or being dropped silently.
  test "GET /components refuses a sort it does not offer" do
    # A plain request rather than `assert_api_response`: the 400 here is the
    # schema validator's own, injected into every operation, and declaring it
    # on this path would replace that injected response.
    get "/api/v1/components", params: {q: {"sorts" => ["sneakyColumn desc"]}}

    assert_response :bad_request
    assert_includes response.parsed_body["details"].to_s, "is not one of"
  end

  test "GET /components searches the description, not only the name" do
    match = create(:component, name: "Nothing Obvious", description: "a quantum enforcement device")
    create(:component, name: "Other", description: "something else")

    assert_api_response :get, 200, params: {q: {"descriptionCont" => "enforcement"}} do
      assert_equal [match.name], parsed_body["items"].map { |item| item["name"] }
    end
  end
  # The index has always carried this field. Moving it to the detail page only
  # would break a client reading `items[].hardpoints`, which marking it optional
  # in the schema documents rather than avoids.
  test "GET /components keeps hardpoints in the list response" do
    assert_api_response :get, 200 do
      assert parsed_body["items"].first.key?("hardpoints")
    end
  end
  # The ransackers behind these already existed -- they are what make the metric
  # sorts work -- but the schema refused the predicate with a 400, so the model
  # could filter on a figure and the API could not.
  test "GET /components filters on a metric range" do
    create(:component, name: "Weak Shield", type_data: {"max_health" => 100})
    create(:component, name: "Strong Shield", type_data: {"max_health" => 9000})

    assert_api_response :get, 200, params: {q: {"maxHealthGteq" => 1000, "nameCont" => "Shield"}} do
      assert_equal ["Strong Shield"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /components filters on both ends of a metric range" do
    create(:component, name: "Small Cooler", type_data: {"cooling_rate" => 10})
    create(:component, name: "Mid Cooler", type_data: {"cooling_rate" => 50})
    create(:component, name: "Big Cooler", type_data: {"cooling_rate" => 500})

    assert_api_response :get, 200, params: {
      q: {"coolingRateGteq" => 20, "coolingRateLteq" => 100, "nameCont" => "Cooler"}
    } do
      assert_equal ["Mid Cooler"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  # A component that carries no such figure is absent rather than sorted to one
  # end: the cast is over a key its `type_data` does not have.
  test "GET /components leaves out a component the metric does not apply to" do
    create(:component, name: "Has The Metric", type_data: {"max_health" => 5000})
    create(:component, name: "Different Category", type_data: {"cooling_rate" => 50})

    assert_api_response :get, 200, params: {q: {"maxHealthGteq" => 1}} do
      names = parsed_body["items"].map { |item| item["name"] }
      assert_includes names, "Has The Metric"
      assert_not_includes names, "Different Category"
    end
  end
end
