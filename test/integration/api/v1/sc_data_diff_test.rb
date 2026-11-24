# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ScDataDiffTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  OLD = "1.0.0-live.1"
  NEW = "1.0.1-live.2"

  api_path "/sc-data/diff" do
    get("How much each catalogue moved between two SC Data builds") do
      operationId "scDataDiffSummary"
      tags "Versions"
      produces "application/json"

      parameter name: "from", in: :query, schema: {type: :string}, required: true
      parameter name: "to", in: :query, schema: {type: :string}, required: true

      response(200, "successful") { schema ::V1::Schemas::ScDataDiffSummary }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/sc-data/diff/{catalogue}" do
    get("What changed in one catalogue between two SC Data builds") do
      operationId "scDataDiff"
      tags "Versions"
      produces "application/json"

      parameter name: "catalogue", in: :path, schema: ::V1::Schemas::Enums::ScDataDiffCatalogueEnum, required: true
      parameter name: "from", in: :query, schema: {type: :string}, required: true
      parameter name: "to", in: :query, schema: {type: :string}, required: true
      parameter name: "kind", in: :query, schema: ::V1::Schemas::Enums::ScDataDiffKindEnum, required: false
      parameter name: "field", in: :query, schema: {type: :string}, required: false
      parameter name: "search", in: :query, schema: {type: :string}, required: false
      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string}, required: false

      response(200, "successful") { schema ::V1::Schemas::ScDataDiff }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  private def change(name, old_size, new_size)
    component = create(:component, :without_build)
    create(:component_build, component:, environment: "live", version: OLD, name:, size: old_size)
    create(:component_build, component:, environment: "live", version: NEW, name:, size: new_size)
    component
  end

  private def diff(**params, &block)
    assert_api_response(:get, 200, api_path: "/sc-data/diff/{catalogue}",
      path_params: {catalogue: "components"}, params: {from: OLD, to: NEW, **params}, &block)
  end

  test "GET /sc-data/diff counts every catalogue" do
    change("Bulwark", "1", "2")

    assert_api_response :get, 200, api_path: "/sc-data/diff", params: {from: OLD, to: NEW} do
      items = parsed_body["items"].index_by { |item| item["catalogue"] }

      assert_equal ScData::BuildDiff::CATALOGUES.keys, items.keys
      assert_equal({"added" => 0, "removed" => 0, "changed" => 1}, items["components"]["counts"])
      assert_not items["models"]["recorded"]
    end
  end

  test "GET /sc-data/diff answers not found for a version with no build" do
    change("Bulwark", "1", "2")

    assert_api_response :get, 404, api_path: "/sc-data/diff", params: {from: OLD, to: "9.9.9-live.404"}
  end

  test "GET /sc-data/diff/{catalogue} carries both values" do
    change("Bulwark", "1", "2")

    diff do
      item = parsed_body["items"].sole

      assert_equal "Bulwark", item["name"]
      assert_equal [{"field" => "size", "from" => "1", "to" => "2"}], item["fields"]
      assert_equal [{"field" => "size", "count" => 1}], parsed_body["fields"]
    end
  end

  test "GET /sc-data/diff/{catalogue} narrows by search, kind and field" do
    change("Bulwark", "1", "2")
    change("Palisade", "1", "2")

    diff(search: "bul") { assert_equal ["Bulwark"], parsed_body["items"].pluck("name") }
    diff(kind: "added") { assert_empty parsed_body["items"] }
    diff(field: "grade") { assert_empty parsed_body["items"] }
  end

  test "GET /sc-data/diff/{catalogue} pages" do
    change("Bulwark", "1", "2")
    change("Palisade", "1", "2")

    diff(perPage: "1", page: "2") do
      assert_equal ["Palisade"], parsed_body["items"].pluck("name")
      assert_equal 2, parsed_body.dig("meta", "pagination", "totalCount")
    end
  end

  test "GET /sc-data/diff/{catalogue} links only a record the served build has" do
    kept = change("Bulwark", "1", "2")
    gone = create(:component, :without_build)
    create(:component_build, component: gone, environment: "live", version: OLD, name: "Palisade")

    diff do
      slugs = parsed_body["items"].to_h { |item| [item["name"], item["slug"]] }

      assert_equal({"Bulwark" => kept.reload.slug, "Palisade" => nil}, slugs)
      assert_not_nil slugs["Bulwark"]
    end
  end

  test "GET /sc-data/diff/{catalogue} names the ship a component is fitted to" do
    component = change("Hull Armor", "1", "2")
    hardpoint = create(:hardpoint, parent: create(:model, name: "Javelin"))
    HardpointBuild.where(hardpoint:).delete_all
    create(:hardpoint_build, hardpoint:, component:, environment: "live", version: NEW)

    diff { assert_equal "Javelin", parsed_body["items"].sole["context"] }
  end
end
