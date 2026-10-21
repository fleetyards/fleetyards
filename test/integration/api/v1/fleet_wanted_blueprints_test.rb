# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetWantedBlueprintsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  PATH = "/fleets/{fleetSlug}/blueprints/wanted"

  api_path PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    get("Blueprints the fleet's members want") do
      operationId "fleetWantedBlueprints"
      tags "Blueprints"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Blueprint.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::BlueprintQuery,
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetWantedBlueprints
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @crafter = create(:user, username: "crafter")
    @reader = create(:user)
    @fleet = create(:fleet, admins: [@reader], members: [@crafter])

    @blueprint = create(:blueprint, name: "Bulldog Repeater", sc_key: "bp_craft_behr_repeater_s3")
    @other = create(:blueprint, name: "Omnisky VI Cannon", sc_key: "bp_craft_amrs_lasercannon_s2")

    create(:user_blueprint, :wanted, user: @crafter, blueprint: @blueprint)
    create(:user_blueprint, user: @crafter, blueprint: @other)
  end

  def membership_for(user)
    @fleet.fleet_memberships.kept.find_by(user_id: user.id)
  end

  test "GET lists what the members want, and who wants it" do
    sign_in @reader

    assert_api_response :get, 200, api_path: PATH, path_params: {fleetSlug: @fleet.slug} do
      items = parsed_body["items"]

      assert_equal [@blueprint.id], items.pluck("blueprint").pluck("id")
      assert_equal 1, items.first["wanterCount"]
      assert_equal ["crafter"], items.first["wanters"].pluck("username")
    end
  end

  # The membership setting that hides what somebody holds hides what they are
  # after with it.
  test "GET leaves out a member who is not sharing" do
    membership_for(@crafter).update!(blueprints_filter: "hide")

    sign_in @reader

    assert_api_response :get, 200, api_path: PATH, path_params: {fleetSlug: @fleet.slug} do
      assert_empty parsed_body["items"]
    end
  end

  test "GET takes the catalogue's filters" do
    create(:user_blueprint, :wanted, user: @reader, blueprint: create(:blueprint, name: "Attrition-3 Repeater"))

    sign_in @reader

    assert_api_response :get, 200, api_path: PATH, path_params: {fleetSlug: @fleet.slug},
      params: {q: {"nameCont" => "Bulldog"}} do
      assert_equal [@blueprint.id], parsed_body["items"].pluck("blueprint").pluck("id")
    end
  end

  test "GET is refused to a role without the privilege" do
    role = create(:fleet_role, fleet: @fleet, name: "Recruit", resource_access: [])
    membership_for(@reader).update!(fleet_role: role)

    sign_in @reader

    assert_api_response :get, 403, api_path: PATH, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET without a session is refused" do
    assert_api_response :get, 401, api_path: PATH, path_params: {fleetSlug: @fleet.slug}
  end
end
