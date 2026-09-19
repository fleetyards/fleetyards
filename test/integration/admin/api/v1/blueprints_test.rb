# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::BlueprintsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/blueprints" do
    get("Blueprints list") do
      operationId "blueprints"
      tags "Blueprints"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Blueprint.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: ::Admin::V1::Schemas::Queries::BlueprintQuery,
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema ::Shared::V1::Schemas::Blueprints
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/blueprints/{id}" do
    parameter name: "id", in: :path, description: "Blueprint id", schema: {type: :string, format: :uuid}, required: true

    get("Blueprint Detail") do
      operationId "blueprint"
      tags "Blueprints"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Blueprint
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
    @user = create(:admin_user, resource_access: [:blueprints])
  end

  # GET /blueprints
  test "GET /blueprints lists blueprints" do
    create_list(:blueprint, 2)
    create(:blueprint, name: "Ballistic Cannon")
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /blueprints filters by nameCont query" do
    create_list(:blueprint, 2)
    create(:blueprint, name: "Ballistic Cannon")
    sign_in @user

    assert_api_response :get, 200, params: {q: {"nameCont" => "Ballistic"}} do
      items = parsed_body["items"]

      assert_equal 1, items.count
      assert_equal "Ballistic Cannon", items.first["name"]
    end
  end

  test "GET /blueprints filters by the catalogue the output is in" do
    create(:blueprint, :for_component, name: "Shield Generator")
    create(:blueprint, :for_equipment, name: "Tractor Beam")
    sign_in @user

    assert_api_response :get, 200, params: {q: {"craftableTypeEq" => "Component"}} do
      assert_equal ["Shield Generator"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  # The half of the question ransack cannot answer: as a ransack scope a
  # boolean is skipped when false, and false is what an admin is asking.
  test "GET /blueprints filters both ways on whether anything hands the recipe out" do
    sourced = create(:blueprint, name: "Handed Out")
    create(:blueprint_source, build: sourced.build)
    create(:blueprint, name: "Nobody Knows")
    sign_in @user

    assert_api_response :get, 200, params: {q: {"withKnownSource" => true}} do
      assert_equal ["Handed Out"], parsed_body["items"].map { |item| item["name"] }
    end

    assert_api_response :get, 200, params: {q: {"withKnownSource" => false}} do
      assert_equal ["Nobody Knows"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  # The five recipes the section exists to surface.
  test "GET /blueprints filters both ways on whether the output resolved" do
    create(:blueprint, :for_component, name: "Makes Something")
    create(:blueprint, :without_craftable, name: "Makes Nothing")
    sign_in @user

    assert_api_response :get, 200, params: {q: {"withCraftable" => true}} do
      assert_equal ["Makes Something"], parsed_body["items"].map { |item| item["name"] }
    end

    assert_api_response :get, 200, params: {q: {"withCraftable" => false}} do
      assert_equal ["Makes Nothing"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /blueprints states whether the output resolved on every row" do
    create(:blueprint, :for_component, name: "Makes Something")
    create(:blueprint, :without_craftable, name: "Makes Nothing")
    sign_in @user

    assert_api_response :get, 200 do
      resolved = parsed_body["items"].index_by { |item| item["name"] }

      assert_not resolved["Makes Something"]["craftableMissing"]
      assert resolved["Makes Nothing"]["craftableMissing"]
    end
  end

  test "GET /blueprints names the build every row was read from" do
    create(:blueprint, name: "Ballistic Cannon")
    sign_in @user

    assert_api_response :get, 200 do
      build = parsed_body["items"].first["build"]

      assert_equal ScData::Source.version, build["version"]
      assert_equal ScData::Source.environment, build["environment"]
    end
  end

  # Where the public list defaults to the build we are on, this one defaults to
  # everything: "what did this load retire" is one of the questions the section
  # answers.
  test "GET /blueprints shows a retired recipe by default and hides it on request" do
    retired = create(:blueprint, :without_build, version: nil, name: "Dropped")
    retired.builds.create!(environment: ScData::Source.environment, version: "0.0.1-live.1", name: "Dropped")
    create(:blueprint, name: "Still Here")
    sign_in @user

    assert_api_response :get, 200 do
      items = parsed_body["items"].index_by { |item| item["name"] }

      assert_equal 2, items.size
      assert items["Dropped"]["retired"]
      assert_equal "0.0.1-live.1", items["Dropped"]["build"]["version"]
    end

    assert_api_response :get, 200, params: {q: {"currentVersion" => true}} do
      assert_equal ["Still Here"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /blueprints paginates with perPage" do
    create_list(:blueprint, 3)
    sign_in @user

    assert_api_response :get, 200, params: {perPage: 2} do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /blueprints returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /blueprints returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # GET /blueprints/:id
  test "GET /blueprints/:id returns the recipe" do
    blueprint = create(:blueprint, :for_component, name: "Ballistic Cannon")
    slot = create(:blueprint_cost_slot, build: blueprint.build)
    create(:blueprint_cost_option, slot:, commodity: create(:commodity, name: "Titanium"))
    create(:blueprint_cost_modifier, slot:)
    create(:blueprint_source, build: blueprint.build, org_name: "Eckhart Security")
    sign_in @user

    assert_api_response :get, 200, path_params: {id: blueprint.id} do
      assert_equal "Ballistic Cannon", parsed_body["name"]
      assert_not parsed_body["craftableMissing"]
      assert_equal "Titanium", parsed_body["costSlots"].first["options"].first["commodity"]["name"]
      assert_equal 1, parsed_body["costSlots"].first["modifiers"].count
      assert_equal ["Eckhart Security"], parsed_body["sources"].map { |source| source["orgName"] }
    end
  end

  test "GET /blueprints/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "5b30f7ab-5c62-4bec-9db7-e187f84f6aeb"}
  end

  test "GET /blueprints/:id returns 401 when not signed in" do
    blueprint = create(:blueprint)

    assert_api_response :get, 401, path_params: {id: blueprint.id}
  end

  test "GET /blueprints/:id returns 403 for admin without access" do
    blueprint = create(:blueprint)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: blueprint.id}
  end
end
