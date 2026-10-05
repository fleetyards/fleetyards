# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FleetsOptionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleets/options" do
    get("Fleet Options") do
      operationId "fleetOptions"
      tags "Fleets"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "q", in: :query, schema: ::Admin::V1::Schemas::Queries::FleetQuery, required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Fleets::Options::FleetOptions
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

  test "GET /fleets/options returns options" do
    create_list(:fleet, 3)
    sign_in @user

    assert_api_response :get, 200
  end

  # Contains-only in name order put a fleet called "Test" behind every other
  # name with "test" in it. The term is hyphenated so no random factory name
  # can match it.
  test "GET /fleets/options ranks a search exact, then prefix, then contains" do
    contains = create(:fleet, name: "A Big Ze-ro Fleet", fid: "BIGZERO")
    prefix = create(:fleet, name: "Ze-ro Squadron", fid: "ZSQUAD")
    exact = create(:fleet, name: "Ze-ro", fid: "ZERO100")
    create(:fleet, name: "Unrelated", fid: "UNREL")
    sign_in @user

    assert_api_response :get, 200, params: {q: {"search" => "ze-ro"}} do
      assert_equal [exact.fid, prefix.fid, contains.fid], parsed_body["items"].pluck("fid")
    end
  end

  test "GET /fleets/options searches the SID as well as the name" do
    by_sid = create(:fleet, name: "Opiepal", fid: "Ze-roSquadron")
    exact_sid = create(:fleet, name: "Woot", fid: "ze-ro")
    sign_in @user

    assert_api_response :get, 200, params: {q: {"search" => "Ze-ro"}} do
      assert_equal [exact_sid.fid, by_sid.fid], parsed_body["items"].pluck("fid")
    end
  end

  test "GET /fleets/options counts each fleet's accepted members" do
    fleet = create(:fleet, name: "Ze-ro", fid: "ZERO100")
    create_list(:fleet_membership, 2, :accepted, fleet:)
    create(:fleet_membership, fleet:)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"search" => "ze-ro"}} do
      assert_equal [fleet.member_count], parsed_body["items"].pluck("memberCount")
    end
  end

  test "GET /fleets/options returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /fleets/options returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
