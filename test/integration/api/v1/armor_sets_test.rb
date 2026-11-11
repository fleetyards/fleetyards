# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ArmorSetsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/armor-sets" do
    get("Armor sets") do
      operationId "armorSets"
      tags "DressingRoom"
      produces "application/json"

      response(200, "successful") { schema ::V1::Schemas::DressingRoom::ArmorSetsList }
      response(403, "feature disabled") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    Flipper.enable(:dressing_room)
    @maker = create(:manufacturer, name: "Clark Defense Systems")
  end

  private def piece(name, slot, **)
    create(:equipment, :armor, name:, slot:, item_type: "medium_armor", manufacturer: @maker, **)
  end

  test "GET /armor-sets puts each maker's pieces of one name together, head to toe, without signing in" do
    %w[Legs Arms Core Helmet].zip(%i[legs arms torso helmet]).each do |word, slot|
      piece("ORC-mkX #{word} Woodland", slot)
    end
    piece("ORC-mkX Backpack Woodland", :backpack, item_type: "medium_backpack")

    assert_api_response :get, 200 do
      assert_equal ["ORC-mkX Woodland"], parsed_body.pluck("name")

      set = parsed_body.first
      assert_equal "Clark Defense Systems", set["manufacturerName"]
      assert_equal "medium_armor", set["itemType"]
      assert_equal %w[helmet torso arms legs backpack], set["pieces"].pluck("slot")
      assert_equal "ORC-mkX Helmet Woodland", set["pieces"].first["name"]
    end
  end

  test "GET /armor-sets leaves out a pair of pieces that only share a colour name" do
    piece("ORC-mkX Helmet Woodland", :helmet)
    piece("ORC-mkX Core Woodland", :torso)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /armor-sets wears the sold piece over a stand-in of the same name" do
    piece("ORC-mkX Helmet Woodland", :helmet, sc_key: "invisible_armor_medium_helmet")
    sold = piece("ORC-mkX Helmet Woodland", :helmet, sc_key: "cds_armor_medium_helmet_01_01_01")
    piece("ORC-mkX Core Woodland", :torso)
    piece("ORC-mkX Arms Woodland", :arms)

    assert_api_response :get, 200 do
      assert_equal sold.slug, parsed_body.first["pieces"].find { |entry| entry["slot"] == "helmet" }["slug"]
    end
  end

  test "GET /armor-sets pictures a set by its core's render, or another piece's without one" do
    render = Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png")
    piece("ORC-mkX Helmet Woodland", :helmet, angled_view: render)
    piece("ORC-mkX Core Woodland", :torso)
    piece("ORC-mkX Arms Woodland", :arms)
    piece("ORC-mkX Helmet Arctic", :helmet)
    piece("ORC-mkX Core Arctic", :torso)
    piece("ORC-mkX Arms Arctic", :arms)

    assert_api_response :get, 200 do
      images = parsed_body.to_h { |set| [set["name"], set["image"]] }

      assert_nil images["ORC-mkX Arctic"]
      assert images["ORC-mkX Woodland"]["url"].present?
    end
  end

  test "GET /armor-sets pictures a set by another piece's render before its core's store image" do
    picture = ->(file) { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/#{file}"), "image/#{File.extname(file).delete(".").sub("jpg", "jpeg")}") }
    piece("ORC-mkX Helmet Woodland", :helmet, angled_view: picture.call("test.png"))
    piece("ORC-mkX Core Woodland", :torso, store_image: picture.call("image.jpg"))
    piece("ORC-mkX Arms Woodland", :arms)

    assert_api_response :get, 200 do
      assert_equal "test.png", parsed_body.first.dig("image", "name")
    end
  end

  test "GET /armor-sets gives a set the piece of its name the game credits to another maker" do
    piece("ORC-mkX Core Woodland", :torso)
    piece("ORC-mkX Arms Woodland", :arms)
    piece("ORC-mkX Legs Woodland", :legs)
    piece("ORC-mkX Helmet Woodland", :helmet, manufacturer: create(:manufacturer, name: "Gallenson Tactical"))

    assert_api_response :get, 200 do
      assert_equal ["ORC-mkX Woodland"], parsed_body.pluck("name")
      assert_equal "Clark Defense Systems", parsed_body.first["manufacturerName"]
      assert_equal %w[helmet torso arms legs], parsed_body.first["pieces"].pluck("slot")
    end
  end

  test "GET /armor-sets is forbidden while the feature is off" do
    Flipper.disable(:dressing_room)

    assert_api_response :get, 403
  end
end
