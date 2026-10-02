# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::LocationsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/locations" do
    get("Locations list") do
      operationId "locations"
      tags "Locations"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Location.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: ::Admin::V1::Schemas::Queries::LocationQuery,
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Locations
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/locations/{id}" do
    parameter name: "id", in: :path, description: "Location id", schema: {type: :string, format: :uuid}, required: true

    get("Location Detail") do
      operationId "location"
      tags "Locations"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Location
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    put("Update Location") do
      operationId "updateLocation"
      tags "Locations"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::LocationInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Location
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
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
    @user = create(:admin_user, resource_access: [:locations])
    @system = create(:location, name: "Nyx System", kind: "system")
    @star = create(:location, name: "Nyx", kind: "star", parent: @system, system: @system)
    @levski = create(:location, name: "Levski", kind: "city", parent: @star, map_parent: @star, system: @system,
      sc_refs: %w[ref-a ref-b], mission_template_refs: %w[template-a])
  end

  test "GET /locations lists places" do
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal ["Levski", "Nyx", "Nyx System"], parsed_body["items"].pluck("name")
      assert_equal %w[ref-a ref-b], parsed_body["items"].first["scRefs"]
    end
  end

  test "GET /locations is refused without the privilege" do
    sign_in create(:admin_user, resource_access: [:missions])

    assert_api_response :get, 403
  end

  test "GET /locations is refused signed out" do
    assert_api_response :get, 401
  end

  test "GET /locations shows a place the current build dropped" do
    create(:location, name: "Port Olisar", version: nil, with_build: false)
    sign_in @user

    assert_api_response :get, 200 do
      olisar = parsed_body["items"].find { |item| item["name"] == "Port Olisar" }

      assert olisar["retired"]
      assert_nil olisar["version"]
    end
  end

  test "GET /locations finds a place by its record key" do
    sign_in @user

    assert_api_response :get, 200, params: {q: {scKeyCont: @levski.sc_key}} do
      assert_equal ["Levski"], parsed_body["items"].pluck("name")
    end
  end

  test "GET /locations/{id} returns the place with what the load linked to it" do
    create(:terminal, name: "Levski", location: @levski, available: false)
    sign_in @user

    assert_api_response :get, 200, params: {id: @levski.id} do
      assert_equal "Nyx", parsed_body.dig("mapParent", "name")
      assert_equal "Nyx System", parsed_body.dig("system", "name")
      assert_equal %w[template-a], parsed_body["missionTemplateRefs"]
      assert_equal [false], parsed_body["terminals"].pluck("available")
    end
  end

  test "GET /locations/{id} 404s for an id nothing carries" do
    sign_in @user

    assert_api_response :get, 404, params: {id: SecureRandom.uuid}
  end

  test "PUT /locations/{id} sets the picture and colour a body is drawn with" do
    sign_in @user

    blob = ActiveStorage::Blob.create_and_upload!(
      io: Rails.root.join("test/fixtures/files/test.png").open,
      filename: "test.png",
      content_type: "image/png"
    )

    assert_api_response :put, 200, path_params: {id: @levski.id}, body: {image: blob.signed_id, color: "#a0522d"} do
      assert_equal "#a0522d", parsed_body["color"]
      assert parsed_body.dig("image", "url").present?
    end

    assert_predicate @levski.reload.image, :attached?
  end

  test "PUT /locations/{id} takes a planet's colour from its picture when none is given" do
    hurston = create(:location, name: "Hurston", kind: "planet", parent: @star, system: @system)
    sign_in @user

    blob = ActiveStorage::Blob.create_and_upload!(
      io: Rails.root.join("test/fixtures/files/test.png").open,
      filename: "test.png",
      content_type: "image/png"
    )

    assert_api_response :put, 200, path_params: {id: hurston.id}, body: {image: blob.signed_id} do
      assert_match(/\A#\h{6}\z/, parsed_body["color"])
    end
  end

  test "PUT /locations/{id} keeps a colour given with the picture" do
    hurston = create(:location, name: "Hurston", kind: "planet", parent: @star, system: @system)
    sign_in @user

    blob = ActiveStorage::Blob.create_and_upload!(
      io: Rails.root.join("test/fixtures/files/test.png").open,
      filename: "test.png",
      content_type: "image/png"
    )

    assert_api_response :put, 200, path_params: {id: hurston.id}, body: {image: blob.signed_id, color: "#a0522d"} do
      assert_equal "#a0522d", parsed_body["color"]
    end
  end

  test "PUT /locations/{id} refuses a colour that is not a hex code" do
    sign_in @user

    assert_api_response :put, 400, path_params: {id: @levski.id}, body: {color: "#zzzzzz"}

    assert_nil @levski.reload.color
  end

  test "PUT /locations/{id} is refused without the privilege" do
    sign_in create(:admin_user, resource_access: [:missions])

    assert_api_response :put, 403, path_params: {id: @levski.id}, body: {color: "#a0522d"}
  end
end
