# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicFleetsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/fleets" do
    get("Fleet directory") do
      operationId "fleetDirectory"
      tags "Fleets"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Fleet.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::FleetDirectoryQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetDirectory
      end

      response(403, "the directory is not rolled out") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_directory")

    @pirates = listed_fleet("PIRATES", name: "Night Pirates", members: 3,
      primary_activity: "piracy", secondary_activity: "smuggling", language: "en",
      commitment: "hardcore", roleplay: true, recruiting: true, alignment: "outlaw")
    @miners = listed_fleet("DIGDEEP", name: "Deep Diggers", members: 2,
      primary_activity: "resources", secondary_activity: "piracy", language: "de",
      commitment: "casual", roleplay: false, recruiting: false, alignment: "lawful",
      default_timezone: "Europe/Berlin")
  end

  def listed_fleet(sid, members:, **attributes)
    fleet = create(:fleet, rsi_sid: sid, created_by: create(:user).id, members: create_list(:user, members - 1),
      **attributes.slice(:name, :alignment, :default_timezone))
    # rubocop:disable Rails/SkipsModelValidations
    fleet.update_columns(rsi_verified_at: Time.current, rsi_verified_sid: sid, rsi_verification_status: :verified,
      **attributes.except(:name, :alignment, :default_timezone))
    # rubocop:enable Rails/SkipsModelValidations
    fleet
  end

  def names
    parsed_body["items"].map { |item| item["name"] }
  end

  test "GET /public/fleets lists listed fleets, the largest first" do
    create(:fleet, rsi_sid: "UNVERIFIED", created_by: create(:user).id, members: [create(:user)])
    listed_fleet("HIDDEN", members: 2, listed: false)
    listed_fleet("PRIVATE", members: 2).update!(public_fleet: false)

    assert_api_response :get, 200 do
      assert_equal ["Night Pirates", "Deep Diggers"], names

      entry = parsed_body["items"].first
      assert_equal "PIRATES", entry["rsiSid"]
      assert_equal 3, entry["memberCount"]
      assert_equal "piracy", entry["primaryActivity"]
      assert_equal "en", entry["language"]
      assert entry["recruiting"]
    end
  end

  test "GET /public/fleets is answered without signing in" do
    assert_api_response :get, 200 do
      assert_equal 2, parsed_body["items"].size
    end
  end

  test "GET /public/fleets searches name, FID and SID" do
    assert_api_response :get, 200, params: {q: {"search" => "digdeep"}} do
      assert_equal ["Deep Diggers"], names
    end

    assert_api_response :get, 200, params: {q: {"search" => "night"}} do
      assert_equal ["Night Pirates"], names
    end
  end

  test "GET /public/fleets matches an activity in either slot" do
    assert_api_response :get, 200, params: {q: {"activityIn" => ["piracy"]}} do
      assert_equal ["Night Pirates", "Deep Diggers"], names
    end

    assert_api_response :get, 200, params: {q: {"activityIn" => ["smuggling"]}} do
      assert_equal ["Night Pirates"], names
    end
  end

  test "GET /public/fleets filters by language, alignment, commitment and timezone" do
    assert_api_response :get, 200, params: {q: {"languageIn" => ["de"]}} do
      assert_equal ["Deep Diggers"], names
    end

    assert_api_response :get, 200, params: {q: {"alignmentIn" => ["outlaw"], "commitmentIn" => ["hardcore"]}} do
      assert_equal ["Night Pirates"], names
    end

    assert_api_response :get, 200, params: {q: {"defaultTimezoneIn" => ["Europe/Berlin"]}} do
      assert_equal ["Deep Diggers"], names
    end
  end

  test "GET /public/fleets filters on recruiting and role play, false included" do
    assert_api_response :get, 200, params: {q: {"recruitingEq" => false}} do
      assert_equal ["Deep Diggers"], names
    end

    assert_api_response :get, 200, params: {q: {"roleplayEq" => true}} do
      assert_equal ["Night Pirates"], names
    end
  end

  test "GET /public/fleets filters and sorts by member count" do
    assert_api_response :get, 200, params: {q: {"memberCountGteq" => 3}} do
      assert_equal ["Night Pirates"], names
    end

    assert_api_response :get, 200, params: {q: {"s" => "memberCount asc"}} do
      assert_equal ["Deep Diggers", "Night Pirates"], names
    end
  end

  test "GET /public/fleets paginates" do
    assert_api_response :get, 200, params: {perPage: 1} do
      assert_equal ["Night Pirates"], names
    end
  end

  test "GET /public/fleets is unavailable until the directory is rolled out" do
    Flipper.disable("fleet_directory")

    assert_api_response :get, 403
  end
end
