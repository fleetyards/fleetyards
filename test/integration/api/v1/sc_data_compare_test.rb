# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ScDataCompareTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  OLD = "1.0.0-live.1"
  NEW = "1.0.1-live.2"
  PTU = "1.0.2-ptu.3"

  api_path "/sc-data/builds" do
    get("SC Data Builds") do
      operationId "scDataBuilds"
      tags "Versions"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::ScDataBuilds
      end
    end
  end

  api_path "/sc-data/compare" do
    get("Compare two SC Data builds") do
      operationId "scDataCompare"
      tags "Versions"
      produces "application/json"

      parameter name: "from", in: :query, schema: {type: :string}, required: true
      parameter name: "to", in: :query, schema: {type: :string}, required: true

      response(200, "successful") do
        schema ::V1::Schemas::ScDataCompare
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  private def build_for(version, environment, component: nil, **facts)
    create(:component_build,
      component: component || create(:component, :without_build),
      environment:, version:, **facts)
  end

  # --- The list of builds -----------------------------------------------------

  # A different list from /sc-data/sources: that one hides everything behind the
  # default, and reaches only as far as the config, which names one version per
  # environment. A patch diff compares against the version before the configured
  # one, so it has to see further.
  test "GET /sc-data/builds lists every build there is a row for, newest first" do
    build_for(OLD, "live")
    build_for(NEW, "live")
    build_for(PTU, "ptu")

    assert_api_response :get, 200, api_path: "/sc-data/builds" do
      assert_equal [PTU, NEW, OLD], parsed_body["items"].map { |item| item["version"] }
    end
  end

  # --- The comparison ---------------------------------------------------------

  test "GET /sc-data/compare reports what moved between two builds" do
    arrived = build_for(NEW, "live").component
    gone = build_for(OLD, "live").component

    assert_api_response :get, 200, api_path: "/sc-data/compare", params: {from: OLD, to: NEW} do
      components = parsed_body.dig("catalogues", "components")

      assert_equal [arrived.id], components["appeared"]
      assert_equal [gone.id], components["vanished"]
      assert_equal({"appeared" => 1, "vanished" => 1, "changed" => 0}, components["counts"])
    end
  end

  test "GET /sc-data/compare names the fields that differ" do
    component = create(:component, :without_build)
    build_for(OLD, "live", component:, name: "Old Name")
    build_for(NEW, "live", component:, name: "New Name")

    assert_api_response :get, 200, api_path: "/sc-data/compare", params: {from: OLD, to: NEW} do
      change = parsed_body.dig("catalogues", "components", "changed").sole

      assert_equal component.id, change["id"]
      assert_equal "New Name", change["name"]
      assert_equal ["name"], change["fields"]
    end
  end

  # The axis the recorded change log cannot reach: it diffs within one
  # environment and never answers "what does ptu have that live does not".
  test "GET /sc-data/compare crosses environments" do
    only_in_ptu = build_for(PTU, "ptu").component
    build_for(NEW, "live")

    assert_api_response :get, 200, api_path: "/sc-data/compare", params: {from: NEW, to: PTU} do
      assert_equal [only_in_ptu.id], parsed_body.dig("catalogues", "components", "appeared")
    end
  end

  # A version names its environment, so one parameter identifies a build and
  # there is no pair to keep consistent.
  test "GET /sc-data/compare reports the builds it compared" do
    build_for(OLD, "live")
    build_for(PTU, "ptu")

    assert_api_response :get, 200, api_path: "/sc-data/compare", params: {from: OLD, to: PTU} do
      assert_equal({"environment" => "live", "version" => OLD}, parsed_body["from"])
      assert_equal({"environment" => "ptu", "version" => PTU}, parsed_body["to"])
    end
  end

  # The parameter is well formed and names a build nothing has a row for, so it
  # is a missing thing rather than a malformed request.
  test "GET /sc-data/compare answers not found for a version with no build" do
    build_for(OLD, "live")

    assert_api_response :get, 404, api_path: "/sc-data/compare",
      params: {from: OLD, to: "9.9.9-live.404"}
  end
end
