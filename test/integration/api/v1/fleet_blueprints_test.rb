# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetBlueprintsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  PATH = "/fleets/{fleetSlug}/blueprints"

  api_path PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    get("Blueprints the fleet's members hold") do
      operationId "fleetBlueprints"
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
        schema ::V1::Schemas::Fleets::FleetBlueprints
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

    create(:user_blueprint, user: @crafter, blueprint: @blueprint)
  end

  def membership_for(user)
    @fleet.fleet_memberships.kept.find_by(user_id: user.id)
  end

  test "GET lists what the members hold, and who holds it" do
    sign_in @reader

    assert_api_response :get, 200, api_path: PATH, path_params: {fleetSlug: @fleet.slug} do
      items = parsed_body["items"]

      assert_equal 1, items.count
      assert_equal @blueprint.id, items.first["blueprint"]["id"]
      assert_equal 1, items.first["ownerCount"]
      assert_equal ["crafter"], items.first["owners"].pluck("username")
    end
  end

  # A recipe two people hold is one row with two names, not two rows. The join
  # is written as an exists check for exactly this.
  test "GET lists a recipe two members hold once" do
    second = create(:user, username: "second")
    create(:fleet_membership, fleet: @fleet, user: second, fleet_role: @fleet.default_member_role, aasm_state: :accepted)
    create(:user_blueprint, user: second, blueprint: @blueprint)

    sign_in @reader

    assert_api_response :get, 200, api_path: PATH, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 1, parsed_body["items"].count
      assert_equal 2, parsed_body["items"].first["ownerCount"]
      assert_equal %w[crafter second], parsed_body["items"].first["owners"].pluck("username").sort
    end
  end

  test "GET leaves out a member who is not sharing" do
    membership_for(@crafter).update!(blueprints_filter: "hide")

    sign_in @reader

    assert_api_response :get, 200, api_path: PATH, path_params: {fleetSlug: @fleet.slug} do
      assert_empty parsed_body["items"]
    end
  end

  # The fleet sees what its own members hold, and nothing else: a marker made
  # by somebody outside it is not the fleet's to read.
  test "GET leaves out a holder who is not in the fleet" do
    create(:user_blueprint, user: create(:user), blueprint: @other)

    sign_in @reader

    assert_api_response :get, 200, api_path: PATH, path_params: {fleetSlug: @fleet.slug} do
      assert_equal [@blueprint.id], parsed_body["items"].pluck("blueprint").pluck("id")
    end
  end

  # What the owners panel on a recipe page asks: the same endpoint, narrowed to
  # one blueprint.
  test "GET narrows to one recipe" do
    create(:user_blueprint, user: @crafter, blueprint: @other)

    sign_in @reader

    assert_api_response :get, 200, api_path: PATH, path_params: {fleetSlug: @fleet.slug},
      params: {q: {"idIn" => [@other.id]}} do
      assert_equal [@other.id], parsed_body["items"].pluck("blueprint").pluck("id")
    end
  end

  test "GET takes the catalogue's filters" do
    create(:user_blueprint, user: @crafter, blueprint: @other)

    sign_in @reader

    assert_api_response :get, 200, api_path: PATH, path_params: {fleetSlug: @fleet.slug},
      params: {q: {"nameCont" => "Omnisky"}} do
      assert_equal [@other.id], parsed_body["items"].pluck("blueprint").pluck("id")
    end
  end

  # "What can the fleet make that I cannot" -- the catalogue's own filter,
  # asked of the fleet's rows.
  test "GET narrows to the recipes the reader does not hold themselves" do
    create(:user_blueprint, user: @crafter, blueprint: @other)
    create(:user_blueprint, user: @reader, blueprint: @blueprint)

    sign_in @reader

    assert_api_response :get, 200, api_path: PATH, path_params: {fleetSlug: @fleet.slug},
      params: {q: {"owned" => false}} do
      assert_equal [@other.id], parsed_body["items"].pluck("blueprint").pluck("id")
    end
  end

  test "GET is refused to a role without the privilege" do
    role = create(:fleet_role, fleet: @fleet, name: "Recruit", resource_access: [])
    membership_for(@reader).update!(fleet_role: role)

    sign_in @reader

    assert_api_response :get, 403, api_path: PATH, path_params: {fleetSlug: @fleet.slug}
  end

  # Not a 403: `set_fleet` resolves the fleet through the authorized scope, so
  # a private fleet is not there to be refused in the first place.
  test "GET does not admit that a fleet exists to somebody outside it" do
    sign_in create(:user)

    assert_api_response :get, 404, api_path: PATH, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET without a session is refused" do
    assert_api_response :get, 401, api_path: PATH, path_params: {fleetSlug: @fleet.slug}
  end
end
