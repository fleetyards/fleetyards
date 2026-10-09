# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FleetsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleets" do
    get("Fleets list") do
      operationId "fleets"
      tags "Fleets"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query, schema: ::Admin::V1::Schemas::Queries::FleetQuery, required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Fleets::Fleets
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:fleets])
  end

  def fleet_with_members(name, count)
    create(:fleet, name:, created_by: create(:user).id, members: create_list(:user, count - 1))
  end

  def names
    parsed_body["items"].map { |item| item["name"] }
  end

  test "GET /fleets lists fleets" do
    create_list(:fleet, 3)
    sign_in @user

    assert_api_response :get, 200
  end

  test "GET /fleets filters by member count and sends it" do
    fleet_with_members("Night Pirates", 3)
    fleet_with_members("Deep Diggers", 1)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"memberCountGteq" => 2}} do
      assert_equal ["Night Pirates"], names
      assert_equal 3, parsed_body["items"].first["memberCount"]
    end

    assert_api_response :get, 200, params: {q: {"memberCountLteq" => 2}} do
      assert_equal ["Deep Diggers"], names
    end

    assert_api_response :get, 200, params: {q: {"s" => "memberCount desc"}} do
      assert_equal ["Night Pirates", "Deep Diggers"], names
    end
  end

  test "GET /fleets sorts by the RSI org's member count and sends it" do
    create(:fleet, :rsi_verified, name: "Large", rsi_sid: "LARGE").update_columns(rsi_member_count: 900)
    create(:fleet, :rsi_verified, name: "Small", rsi_sid: "SMALL").update_columns(rsi_member_count: 30)
    create(:fleet, name: "Uncounted")
    sign_in @user

    assert_api_response :get, 200, params: {q: {"s" => "rsiMemberCount desc"}} do
      assert_equal ["Large", "Small", "Uncounted"], names
      assert_equal [900, 30, nil], parsed_body["items"].map { |item| item["rsiMemberCount"] }
    end
  end

  test "GET /fleets filters by RSI verification either way" do
    create(:fleet, :rsi_verified, name: "Verified", rsi_sid: "VERIFIED")
    create(:fleet, name: "Unclaimed")
    create(:fleet, :rsi_verified, name: "Moved", rsi_sid: "MOVED").update_columns(rsi_sid: "ELSEWHERE")
    sign_in @user

    assert_api_response :get, 200, params: {q: {"rsiVerifiedEq" => true}} do
      assert_equal ["Verified"], names
    end

    assert_api_response :get, 200, params: {q: {"rsiVerifiedEq" => false}} do
      assert_equal ["Moved", "Unclaimed"], names
    end
  end

  test "GET /fleets filters by visibility, recruiting and creation day" do
    create(:fleet, name: "Open", recruiting: true, created_at: 3.days.ago)
    create(:fleet, :private, name: "Closed", created_at: 10.days.ago)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"publicFleetEq" => false}} do
      assert_equal ["Closed"], names
    end

    assert_api_response :get, 200, params: {q: {"recruitingEq" => true}} do
      assert_equal ["Open"], names
    end

    assert_api_response :get, 200, params: {q: {"createdOnGteq" => 5.days.ago.to_date.iso8601}} do
      assert_equal ["Open"], names
    end

    assert_api_response :get, 200, params: {q: {"createdOnLteq" => 3.days.ago.to_date.iso8601}} do
      assert_equal ["Closed", "Open"], names
    end
  end

  test "GET /fleets returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /fleets returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
