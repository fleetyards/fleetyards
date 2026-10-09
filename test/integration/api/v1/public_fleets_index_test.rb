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

    # Fewer members on Fleetyards than the miners, more on RSI.
    @pirates = listed_fleet("PIRATES", name: "Night Pirates", members: 2, rsi_member_count: 120,
      primary_activity: "piracy", secondary_activity: "smuggling", language: "en",
      commitment: "hardcore", roleplay: true, recruiting: true, alignment: "outlaw")
    @miners = listed_fleet("DIGDEEP", name: "Deep Diggers", members: 3, rsi_member_count: 40,
      primary_activity: "resources", secondary_activity: "piracy", language: "de",
      commitment: "casual", roleplay: false, recruiting: false, alignment: "lawful",
      default_timezone: "Europe/Berlin")
  end

  def listed_fleet(sid, members:, **attributes)
    fleet = create(:fleet, rsi_sid: sid, created_by: create(:user).id, members: create_list(:user, members - 1),
      **attributes.slice(:name, :alignment, :default_timezone))
    fleet.update_columns(rsi_verified_at: Time.current, rsi_verified_sid: sid, rsi_verification_status: :verified,
      **attributes.except(:name, :alignment, :default_timezone))
    fleet
  end

  def names
    parsed_body["items"].map { |item| item["name"] }
  end

  test "GET /public/fleets lists listed fleets, the largest RSI org first" do
    create(:fleet, rsi_sid: "UNVERIFIED", created_by: create(:user).id, members: [create(:user)])
    listed_fleet("HIDDEN", members: 2, listed: false)
    listed_fleet("PRIVATE", members: 2).update!(public_fleet: false)

    assert_api_response :get, 200 do
      assert_equal ["Night Pirates", "Deep Diggers"], names

      entry = parsed_body["items"].first
      assert_equal "PIRATES", entry["rsiSid"]
      assert_equal 120, entry["memberCount"]
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
    assert_api_response :get, 200, params: {q: {"memberCountGteq" => 100}} do
      assert_equal ["Night Pirates"], names
    end

    assert_api_response :get, 200, params: {q: {"memberCountLteq" => 100}} do
      assert_equal ["Deep Diggers"], names
    end

    assert_api_response :get, 200, params: {q: {"s" => "memberCount asc"}} do
      assert_equal ["Deep Diggers", "Night Pirates"], names
    end
  end

  test "GET /public/fleets sorts a fleet RSI has not counted yet last" do
    listed_fleet("NEWCOMER", name: "Newcomers", members: 5)

    assert_api_response :get, 200, params: {q: {"s" => "memberCount desc"}} do
      assert_equal ["Night Pirates", "Deep Diggers", "Newcomers"], names
      assert_nil parsed_body["items"].last["memberCount"]
    end
  end

  test "GET /public/fleets breaks a tie on member count by name" do
    listed_fleet("ALPHA", name: "Alpha Wing", members: 2, rsi_member_count: 40)

    assert_api_response :get, 200, params: {q: {"s" => "memberCount desc"}} do
      assert_equal ["Night Pirates", "Alpha Wing", "Deep Diggers"], names
    end
  end

  test "GET /public/fleets pages through fleets that share a count and a name" do
    twins = Array.new(2) { |index| listed_fleet("TWIN#{index}", name: "Twin Fleet", members: 2) }

    seen = (1..4).flat_map do |page|
      assert_api_response :get, 200, params: {perPage: 1, page:, q: {"search" => "twin"}}
      parsed_body["items"].map { |item| item["id"] }
    end

    assert_equal twins.map(&:id).sort, seen.sort
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
