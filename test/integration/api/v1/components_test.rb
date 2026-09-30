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

  test "GET /components serves the first page given a nested page" do
    assert_api_response :get, 200, params: {page: {"x" => 1}} do
      assert_equal @components.map(&:id).sort, parsed_body["items"].pluck("id").sort
      assert_equal 1, parsed_body.dig("meta", "pagination", "currentPage")
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
    create(:component, name: "Shieldprobe Weak", type_data: {"max_health" => 100})
    create(:component, name: "Shieldprobe Strong", type_data: {"max_health" => 9000})

    # The decoy is what the probe name exists for, and it stays. `setup` makes
    # two components before every test in this file and the factory names them
    # `Faker::Name.name`, so the surname "Shields" satisfies a `nameCont` of
    # "Shield" -- which is how this test blocked the merge queue once, on a
    # draw nobody could reproduce from the diff.
    #
    # A sort is where that bites: it keeps every row it matches, including one
    # carrying no metric at all. The range filters below are accidentally safe,
    # because a component whose `type_data` has no such key is dropped by the
    # predicate itself.
    create(:component, name: "Enid Shields DDS")

    assert_api_response :get, 200, params: {q: {"sorts" => ["maxHealth desc"], "nameCont" => "Shieldprobe"}} do
      assert_equal ["Shieldprobe Strong", "Shieldprobe Weak"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /components serves a mount's turn rate, angle limits and who controls it" do
    create(:component, name: "Turretprobe", category: "turret",
      type_data: {
        "yaw_speed" => 95.0, "pitch_speed" => 60.0, "control" => "remote", "signature_ir" => 0.0,
        "min_yaw" => -180.0, "max_yaw" => 180.0, "min_pitch" => -85.0, "max_pitch" => 0.0, "pitch_limits_vary" => true
      })

    assert_api_response :get, 200, params: {q: {"nameCont" => "Turretprobe"}} do
      type_data = parsed_body["items"].sole["typeData"]

      assert_in_delta 95.0, type_data["yawSpeed"]
      assert_in_delta 60.0, type_data["pitchSpeed"]
      assert_equal "remote", type_data["control"]
      assert_in_delta(-85.0, type_data["minPitch"])
      assert type_data["pitchLimitsVary"]
    end
  end

  test "GET /components serves a missile's seeker, flight and fuse" do
    create(:component, name: "Missileprobe", category: "weapons",
      type_data: {
        "damage_per_shot" => {"physical" => 650.0}, "tracking_signal" => "Infrared", "lock_angle" => 60.0,
        "dumbfire" => true, "boost_phase_duration" => 2.0, "arm_time" => 1.5, "blast_radius_max" => 5.0,
        "power_consumption" => 1.0, "signature_ir" => 120.0
      })

    assert_api_response :get, 200, params: {q: {"nameCont" => "Missileprobe"}} do
      type_data = parsed_body["items"].sole["typeData"]

      assert_in_delta 60.0, type_data["lockAngle"]
      assert type_data["dumbfire"]
      assert_in_delta 2.0, type_data["boostPhaseDuration"]
      assert_in_delta 5.0, type_data["blastRadiusMax"]
      assert_in_delta 120.0, type_data["signatureIr"]
    end
  end

  test "GET /components serves a bomb's drop angle and a rack's launch delay" do
    create(:component, name: "Ordnanceprobe Bomb", category: "weapons",
      type_data: {"damage_per_shot" => {"physical" => 22_346.0}, "max_drop_angle" => 90.0, "arm_time" => 3.0})
    create(:component, name: "Ordnanceprobe Rack", category: "missile_racks",
      type_data: {"launch_delay" => 0.125, "ignite_on_pylon" => false, "signature_em" => 0.0})

    assert_api_response :get, 200, params: {q: {"nameCont" => "Ordnanceprobe"}} do
      by_name = parsed_body["items"].index_by { |item| item["name"] }

      assert_in_delta 90.0, by_name["Ordnanceprobe Bomb"]["typeData"]["maxDropAngle"]
      assert_in_delta 0.125, by_name["Ordnanceprobe Rack"]["typeData"]["launchDelay"]
      assert_equal false, by_name["Ordnanceprobe Rack"]["typeData"]["igniteOnPylon"]
    end
  end

  # Numerically, which is the whole reason `sizeOrder` exists as a name of its
  # own: `size` is a string ransacker, so ordering on it puts 10 and 12 ahead
  # of 2.
  test "GET /components serves a mining laser's, a mining module's and a salvage modifier's stats" do
    create(:component, name: "Miningprobe Laser", category: "weapons", type_data: {
      "beam" => true,
      "mining" => {
        "fracture_power_min" => 117.0, "fracture_power_max" => 2340.0, "extraction_power" => 1850.0,
        "optimal_range" => 60.0, "max_range" => 180.0, "module_slots" => 1,
        "modifiers" => {"instability" => -35.0, "inert_materials" => -30.0}
      }
    })
    create(:component, name: "Miningprobe Module", category: "utility", type_data: {
      "mining_module" => true, "activation" => "active", "charges" => 7, "duration" => 15.0,
      "fracture_power" => 50.0, "modifiers" => {"resistance" => -15.5}
    })
    create(:component, name: "Miningprobe Scraper", category: "utility", type_data: {
      "salvage_modifier" => true, "salvage_speed" => 0.6, "radius" => 1.5, "extraction_efficiency" => 1.0
    })

    assert_api_response :get, 200, params: {q: {"nameCont" => "Miningprobe"}} do
      by_name = parsed_body["items"].index_by { |item| item["name"] }

      mining = by_name["Miningprobe Laser"].dig("typeData", "mining")
      assert_in_delta 117.0, mining["fracturePowerMin"]
      assert_in_delta(-30.0, mining.dig("modifiers", "inertMaterials"))

      mining_module = by_name["Miningprobe Module"]["typeData"]
      assert_equal "active", mining_module["activation"]
      assert_in_delta 50.0, mining_module["fracturePower"]

      assert_in_delta 0.6, by_name["Miningprobe Scraper"].dig("typeData", "salvageSpeed")
    end
  end

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

  test "GET /components serves a component's health, mass, repair and distortion" do
    create(:component, name: "Durabilityprobe", durability: {
      "health" => 410.0, "mass" => 630.0,
      "resistances" => {"physical" => 0.85, "thermal" => 0.1},
      "self_repair" => {"time" => 56.0, "health_ratio" => 0.2, "max_repairs" => 1},
      "distortion" => {"maximum" => 3500.0, "warning_ratio" => 0.75, "recovery_ratio" => 0.0, "decay_rate" => 233.3333, "decay_delay" => 3.0}
    })

    assert_api_response :get, 200, params: {q: {"nameCont" => "Durabilityprobe"}} do
      durability = parsed_body["items"].sole["durability"]

      assert_in_delta 630.0, durability["mass"]
      assert_in_delta 0.2, durability.dig("selfRepair", "healthRatio")
      assert_in_delta 0.75, durability.dig("distortion", "warningRatio")
      assert_in_delta 0.1, durability.dig("resistances", "thermal")
    end
  end

  test "GET /components serves a quantum drive's interdiction time in both modes" do
    create(:component, name: "Quantumprobe", category: "quantumdrive", type_data: {
      "drive_speed" => 263_400_000.0, "interdiction_effect_time" => 2.6, "signature_ir" => 0.0,
      "spline_jump_params" => {"drive_speed" => 400_000.0, "interdiction_effect_time" => 5.0}
    })

    assert_api_response :get, 200, params: {q: {"nameCont" => "Quantumprobe"}} do
      type_data = parsed_body["items"].sole["typeData"]

      assert_in_delta 2.6, type_data["interdictionEffectTime"]
      assert_in_delta 5.0, type_data.dig("splineJumpParams", "interdictionEffectTime")
    end
  end

  test "GET /components serves a jump drive's tunnel flight" do
    create(:component, name: "Jumpprobe", category: "jumpdrive", type_data: {
      "tuning_rate" => 0.26, "exit_speed" => 200.0, "max_tunnel_speed" => 1300.0, "respool_time" => 3.0, "signature_em" => 0.0
    })

    assert_api_response :get, 200, params: {q: {"nameCont" => "Jumpprobe"}} do
      type_data = parsed_body["items"].sole["typeData"]

      assert_in_delta 200.0, type_data["exitSpeed"]
      assert_in_delta 1300.0, type_data["maxTunnelSpeed"]
    end
  end

  test "GET /components serves a radar's detection modes, ground-vehicle penalty and assist buffer" do
    create(:component, name: "Radarprobe", category: "radar", type_data: {
      "aim_assist_range" => 632.5, "aim_assist_buffer" => 80.0, "signature_ir" => 0.0,
      "signature_detection" => {"cs" => {"sensitivity" => 0.5, "piercing" => 0.25, "passive" => false, "active" => true}},
      "contact_sensitivity" => [{"sensitivity_addition" => -0.65, "contact_groups" => ["GroundVehicle"]}]
    })

    assert_api_response :get, 200, params: {q: {"nameCont" => "Radarprobe"}} do
      type_data = parsed_body["items"].sole["typeData"]

      assert_in_delta 80.0, type_data["aimAssistBuffer"]
      assert_equal false, type_data.dig("signatureDetection", "cs", "passive")
      assert_equal ["GroundVehicle"], type_data.dig("contactSensitivity", 0, "contactGroups")
    end
  end

  test "GET /components serves a thruster's vectoring range and VTOL-only flag" do
    create(:component, name: "Thrusterprobe", category: "thrusters", type_data: {
      "thrust_capacity" => 1_282_107.0, "thruster_type" => "Retro", "fuel_burn_rate_per10_k_newton" => 0.05,
      "vtol_only" => true, "signature_em" => 0.0,
      "gimbal" => {"min_pitch" => -90.0, "max_pitch" => 90.0, "min_yaw" => -30.0, "max_yaw" => 30.0}
    })

    assert_api_response :get, 200, params: {q: {"nameCont" => "Thrusterprobe"}} do
      type_data = parsed_body["items"].sole["typeData"]

      assert type_data["vtolOnly"]
      assert_in_delta(-30.0, type_data.dig("gimbal", "minYaw"))
    end
  end

  test "GET /components serves life-support output, EMP and QED typeData" do
    create(:component, name: "Lifeprobe", category: "lifesupport", type_data: {"life_support_generation" => 0.05, "power_consumption" => 1.0})
    create(:component, name: "Empprobe", category: "weapons", type_data: {"emp_radius" => 4500.0, "distortion_damage" => 6000.0, "charge_time" => 20.0, "signature_ir" => 0.0})
    create(:component, name: "Qedprobe", category: "quantumenforcementdevice", type_data: {
      "jammer_settings" => {"jammer_range" => 20_000.0},
      "quantum_interdiction_pulse_settings" => {"radius_meters" => 20_000.0, "activation_phase_duration_seconds" => 1.0}
    })

    assert_api_response :get, 200, params: {q: {"nameCont" => "probe"}, perPage: 50} do
      by_name = parsed_body["items"].index_by { |item| item["name"] }

      assert_in_delta 0.05, by_name["Lifeprobe"].dig("typeData", "lifeSupportGeneration")
      assert_in_delta 4500.0, by_name["Empprobe"].dig("typeData", "empRadius")
      assert_in_delta 20_000.0, by_name["Qedprobe"].dig("typeData", "jammerSettings", "jammerRange")
      assert_in_delta 1.0, by_name["Qedprobe"].dig("typeData", "quantumInterdictionPulseSettings", "activationPhaseDurationSeconds")
    end
  end

  # Rows loaded before the parser read these blocks carry a `lifetime` the
  # schema does not describe, and nothing else.
  test "GET /components leaves out durability that only an older load wrote" do
    create(:component, name: "Legacyprobe", durability: {"lifetime" => 720.0})

    assert_api_response :get, 200, params: {q: {"nameCont" => "Legacyprobe"}} do
      assert_not parsed_body["items"].sole.key?("durability")
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

  test "GET /components serves a gun's spread" do
    create(:component, name: "Spreadprobe", category: "weapons", component_sub_type: "Gun",
      type_data: {"fire_rate" => 50.0, "max_ammo" => 270, "spread" => {"min" => 0.2, "max" => 0.2, "first_attack" => 0.025, "attack" => 0.025, "decay" => 0.05}})

    assert_api_response :get, 200, params: {q: {"nameCont" => "Spreadprobe"}} do
      spread = parsed_body["items"].sole["typeData"]["spread"]

      assert_in_delta 0.2, spread["max"]
      assert_in_delta 0.025, spread["firstAttack"]
      assert_in_delta 0.05, spread["decay"]
    end
  end
end
