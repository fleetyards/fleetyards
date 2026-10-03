# frozen_string_literal: true

require "openapi_helper"

class Api::V1::LocationsJumpPointsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/locations/jump-points" do
    get("Location jump points") do
      operationId "locationJumpPoints"
      tags "Locations"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::LocationJumpPointsList
      end
    end
  end

  setup do
    @stanton = create(:location, name: "Stanton System", sc_key: "StantonSolarSystem", kind: "system")
    @pyro = create(:location, name: "Pyro System", sc_key: "PyroSolarSystem", kind: "system")
    @nyx = create(:location, name: "Nyx System", sc_key: "NyxSolarSystem", kind: "system")
    stanton_star = create(:location, name: "Stanton", sc_key: "StantonStar", kind: "star", parent: @stanton, system: @stanton)
    create(:location, name: "Nyx", sc_key: "NyxStar", kind: "star", parent: @nyx, system: @nyx)

    create(:location, name: "Stanton-Pyro Jump Point", sc_key: "JumpPoint_Stanton_Pyro", kind: "jump_point", parent: stanton_star, system: @stanton)
    create(:location, name: "Pyro-Stanton Jump Point", sc_key: "JumpPoint_Pyro_Stanton", kind: "jump_point", system: @pyro)
    create(:location, name: "Stanton - Terra Jump Point", sc_key: "JumpPoint_Stanton_Terra", kind: "jump_point", parent: stanton_star, system: @stanton)
  end

  test "GET /locations/jump-points names where each jump point leads" do
    assert_api_response :get, 200 do
      by_name = parsed_body.index_by { |entry| entry.dig("location", "name") }

      assert_equal @pyro.id, by_name.dig("Stanton-Pyro Jump Point", "destinationSystemId")
      assert_equal @pyro.id, by_name.dig("Pyro-Stanton Jump Point", "systemId")
      assert_equal "Stanton", by_name.dig("Pyro-Stanton Jump Point", "destinationName")
    end
  end

  test "GET /locations/jump-points names a system that is not listed without an id" do
    assert_api_response :get, 200 do
      terra = parsed_body.find { |entry| entry.dig("location", "name") == "Stanton - Terra Jump Point" }

      assert_equal "Terra", terra["destinationName"]
      assert_nil terra["destinationSystemId"]
    end
  end

  test "GET /locations/jump-points takes the destination from the gateway over the key" do
    stanton_star = Location.find_by!(sc_key: "StantonStar")
    gateway = create(:location, name: "Nyx Gateway", sc_key: "RR_JP_StantonMagnus", kind: "station", parent: stanton_star, system: @stanton)
    create(:location, name: "Stanton - Magnus Jump Point", sc_key: "JumpPoint_Stanton_Magnus", kind: "jump_point", parent: gateway, system: @stanton)

    assert_api_response :get, 200 do
      magnus = parsed_body.find { |entry| entry.dig("location", "name") == "Stanton - Magnus Jump Point" }

      assert_equal "Nyx", magnus["destinationName"]
      assert_equal @nyx.id, magnus["destinationSystemId"]
    end
  end

  test "GET /locations/jump-points leaves out what only sits at a jump point" do
    jump_point = Location.find_by!(sc_key: "JumpPoint_Stanton_Pyro")
    create(:location, name: "Stanton-Pyro Jump Point Wreck Site", sc_key: "JumpPoint_Stanton_Pyro_Wrecksite", kind: "jump_point", parent: jump_point, system: @stanton)

    assert_api_response :get, 200 do
      refute_includes parsed_body.map { |entry| entry.dig("location", "name") }, "Stanton-Pyro Jump Point Wreck Site"
    end
  end

  test "GET /locations/jump-points leaves out the hidden systems" do
    ellis = create(:location, name: "Ellis System", sc_key: "EllisSolarSystem", kind: "system")
    create(:location, name: "Ellis - Stanton Jump Point", sc_key: "JumpPoint_Ellis_Stanton", kind: "jump_point", system: ellis)
    create(:location, name: "Stanton - Ellis Jump Point", sc_key: "JumpPoint_Stanton_Ellis", kind: "jump_point", system: @stanton)

    assert_api_response :get, 200 do
      names = parsed_body.map { |entry| entry.dig("location", "name") }
      ellis_exit = parsed_body.find { |entry| entry["destinationName"] == "Ellis" }

      refute_includes names, "Ellis - Stanton Jump Point"
      assert_nil ellis_exit["destinationSystemId"]
    end
  end
end
