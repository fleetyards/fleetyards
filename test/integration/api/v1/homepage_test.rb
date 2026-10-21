# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HomepageTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/homepage" do
    get("Homepage") do
      operationId "homepage"
      tags "Homepage"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Homepage
      end
    end
  end

  test "GET /homepage answers with nothing to offer yet" do
    assert_api_response :get, 200 do
      assert_equal [], parsed_body["searchSuggestions"]
      assert_nil parsed_body["featuredShip"]
    end
  end

  test "GET /homepage suggests from the catalogue and features one of the ships with its picture" do
    png = Rails.root.join("test/fixtures/files/test.png")
    ship = create(:model, name: "Carrack", manufacturer: create(:manufacturer, name: "Anvil Aerospace"))
    ship.angled_view.attach(io: File.open(png), filename: "angled.png")
    create(:commodity, name: "Quantainium")
    HomepageSetting.create!(featured_model_ids: [ship.id])
    HomepageSetting.any_instance.stubs(:featured_ship).returns(ship)

    assert_api_response :get, 200 do
      assert_equal ["Carrack", "Quantainium"], parsed_body["searchSuggestions"]
      assert_equal "Carrack", parsed_body.dig("featuredShip", "name")
      assert_equal "Anvil Aerospace", parsed_body.dig("featuredShip", "manufacturerName")
      assert_equal "angled.png", parsed_body.dig("featuredShip", "image", "name")
    end
  end

  test "GET /homepage leaves out a featured ship nobody can open" do
    HomepageSetting.create!(featured_model_ids: [create(:model, hidden: true).id])

    assert_api_response :get, 200 do
      assert_nil parsed_body["featuredShip"]
    end
  end
end
