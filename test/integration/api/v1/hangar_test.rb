# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar" do
    delete("Clear your personal Hangar") do
      operationId "destroyHangar"
      tags "Hangar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "successful")

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    get("Your personal Hangar") do
      operationId "hangar"
      tags "Hangar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {
        type: :string, default: Vehicle.default_per_page
      }, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::HangarQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::Hangar
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "filters by inclusive cargo bounds in SCU" do
    user = create(:user)
    sign_in user
    models = [0, 0.5, 32, 64].map { |cargo| create(:model, cargo:, keep_cargo: true) }
    models.each { |model| create(:vehicle, user: user, model:) }

    [
      [{cargoGteq: 0.5}, models.drop(1)],
      [{cargoLteq: 0.5}, models.first(2)],
      [{cargoGteq: 0.5, cargoLteq: 32}, models[1..2]],
      [{cargoGteq: 0, cargoLteq: 0}, models.first(1)]
    ].each do |query, expected|
      assert_api_response :get, 200, params: {q: query} do
        assert_equal expected.map(&:id).sort, parsed_body["items"].map { |item| item.dig("model", "id") }.sort
      end
    end
  end

  test "filters, sorts and lists the cargo a vehicle carries as fitted" do
    user = create(:user)
    sign_in user
    model = create(:model, production_status: "flight-ready", cargo: 0, keep_cargo: true)
    front_cargo = create(:model_module, cargo: 38)
    rear_cargo = create(:model_module, cargo: 36)
    create(:module_hardpoint, model:, model_module: front_cargo, slot: "hardpoint_front_module")
    create(:module_hardpoint, model:, model_module: rear_cargo, slot: "hardpoint_rear_module")
    fitted = create(:vehicle, user:, model:)
    create(:vehicle_loadout, :fleetyards, :active, vehicle: fitted,
      item_list: [{slot_path: "hardpoint_rear_module", item_type: "ModelModule", item_id: rear_cargo.id}])
    bare = create(:vehicle, user:, model:)

    [
      [{cargoGteq: 30}, [fitted]],
      [{cargoLteq: 30}, [bare]],
      [{withCargo: true}, [fitted]]
    ].each do |query, expected|
      assert_api_response :get, 200, params: {q: query} do
        assert_equal expected.map(&:id), parsed_body["items"].map { |item| item["id"] }
      end
    end

    assert_api_response :get, 200, params: {q: {sorts: ["modelCargo desc"]}} do
      items = parsed_body["items"]

      assert_equal [fitted.id, bare.id], items.map { |item| item["id"] }
      assert_equal [36.0, 0.0], items.map { |item| item["cargo"] }
      assert_equal [nil, 74.0], items.map { |item| item["cargoWithModules"] }
    end
  end

  # A carrier holding a dock of each kind takes the branch that used to hand a
  # Hash to `or`, which Rails refuses outright -- so this filter answered with a
  # 500 for exactly the three ships anybody would pick: Polaris, Carrack, 890
  # Jump.
  test "GET /hangar filters by a carrier that takes both ships and vehicles" do
    user = create(:user)
    carrier = create(:model, slug: "carrier-with-both")
    create(:dock, :with_dimensions, parent: carrier, dock_type: :hangar)
    create(:dock, :with_dimensions, parent: carrier, dock_type: :garage)

    fits = create(:model, ground: false, length: 20.0, beam: 10.0, height: 5.0)
    too_big = create(:model, ground: false, length: 200.0, beam: 100.0, height: 50.0)
    create(:vehicle, user:, model: fits, wanted: false)
    create(:vehicle, user:, model: too_big, wanted: false)

    sign_in user

    assert_api_response :get, 200, params: {q: {willItFit: carrier.slug}} do
      slugs = parsed_body["items"].map { |item| item.dig("model", "slug") }

      assert_includes slugs, fits.slug
      assert_not_includes slugs, too_big.slug
    end
  end

  test "DELETE /hangar clears the hangar" do
    user = create(:user, vehicle_count: 2)
    create(:hangar_pledge_item, user:)
    create(:hangar_pledge_item, user:, kind: "flair", name: "Space Globe - Terra")
    other = create(:hangar_pledge_item)
    sign_in user

    assert_api_response :delete, 204 do
      assert_equal 0, user.vehicles.where(wanted: false).count
      assert_empty user.hangar_pledge_items
      assert HangarPledgeItem.exists?(other.id)
    end
  end

  test "DELETE /hangar returns 401 when not signed in" do
    assert_api_response :delete, 401
  end

  test "GET /hangar returns the user's vehicles" do
    user = create(:user, vehicle_count: 3)
    sign_in user

    assert_api_response :get, 200 do
      assert_operator parsed_body["items"].count, :>, 0
    end
  end

  test "GET /hangar filters by focusIn and stealthEq through each vehicle's model" do
    user = create(:user)
    ghost = create(:vehicle, user:, model: create(:model, foci: %w[medium_fighter], stealth: true))
    create(:vehicle, user:, model: create(:model, foci: %w[medium_fighter]))
    create(:vehicle, user:, model: create(:model, foci: %w[freight], stealth: true))
    sign_in user

    assert_api_response :get, 200, params: {q: {focusIn: %w[fighter], stealthEq: true}} do
      assert_equal [ghost.id], parsed_body["items"].map { |item| item["id"] }
    end
  end

  test "GET /hangar leaves out the ships its owner hid, and lists them on request" do
    user = create(:user)
    shown = create(:vehicle, user:, wanted: false)
    hidden = create(:vehicle, user:, wanted: false, hidden_by_user: true)
    sign_in user

    assert_api_response :get, 200 do
      ids = parsed_body["items"].pluck("id")

      assert_includes ids, shown.id
      assert_not_includes ids, hidden.id
    end

    assert_api_response :get, 200, params: {q: {hiddenByUserEq: "true"}} do
      assert_equal [shown.id, hidden.id].sort, parsed_body["items"].pluck("id").sort
    end

    assert_api_response :get, 200, params: {q: {hiddenByUserEq: "only"}} do
      assert_equal [hidden.id], parsed_body["items"].pluck("id")
      assert_equal true, parsed_body["items"].first["hiddenByUser"]
    end
  end

  test "GET /hangar lists a loaner once when hidden ships are shown alongside the rest" do
    user = create(:user)
    loaner_model = create(:model)
    create(:vehicle, user:, wanted: false, hidden_by_user: true, model: create(:model).tap { |m| m.loaners << loaner_model })
    create(:vehicle, user:, wanted: false, model: create(:model).tap { |m| m.loaners << loaner_model })
    sign_in user

    assert_api_response :get, 200, params: {q: {hiddenByUserEq: "true", loanerEq: "only"}} do
      assert_equal [loaner_model.slug], parsed_body["items"].map { |item| item.dig("model", "slug") }
    end
  end

  test "GET /hangar filters by query" do
    user = create(:user, vehicle_count: 3)
    sign_in user

    assert_api_response :get, 200, params: {q: {"modelNameOrModelDescriptionCont" => user.vehicles.first.model.name}} do
      assert_operator parsed_body["items"].count, :>=, 1
    end
  end

  test "GET /hangar filters by model" do
    user = create(:user)
    model = create(:model)
    matching = create(:vehicle, user:, wanted: false, model:)
    create(:vehicle, user:, wanted: false)
    sign_in user

    assert_api_response :get, 200, params: {q: {modelSlugIn: [model.slug]}} do
      assert_equal [matching.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /hangar honours sort orders" do
    user = create(:user, :with_rsi_handle)
    model_alpha = create(:model, name: "Alpha")
    model_bravo = create(:model, name: "Bravo")
    model_charlie = create(:model, :with_store_image, name: "Charlie")
    create(:vehicle, user: user, model: model_alpha)
    create(:vehicle, user: user, model: model_bravo)
    create(:vehicle, user: user, model: model_charlie)
    sign_in user

    assert_api_response :get, 200, params: {q: {"sorts" => "modelName asc"}} do
      names = parsed_body["items"].map { |m| m.dig("model", "name") }
      assert_equal %w[Alpha Bravo Charlie], names
    end
  end

  test "GET /hangar sorts by the owner's rank" do
    user = create(:user)
    alpha, bravo, charlie = %w[Alpha Bravo Charlie].map { |name| create(:vehicle, user:, name:) }
    alpha.move_next_to!(charlie, after: true)
    sign_in user

    assert_api_response :get, 200, params: {q: {"sorts" => "rank asc"}} do
      assert_equal [bravo.id, charlie.id, alpha.id], parsed_body["items"].map { |item| item["id"] }
    end
  end

  # Until the backfill reaches them, unranked ships come after the ranked ones in
  # the order the backfill will rank them.
  test "GET /hangar sorts unranked ships behind the ranked ones in the standard order" do
    user = create(:user)
    charlie, alpha, bravo = %w[Charlie Alpha Bravo].map { |name| create(:vehicle, user:, name:) }
    Vehicle.where(id: [alpha.id, bravo.id]).update_all(rank: nil)
    sign_in user

    assert_api_response :get, 200, params: {q: {"sorts" => "rank asc"}} do
      assert_equal [charlie.id, alpha.id, bravo.id], parsed_body["items"].map { |item| item["id"] }
    end
  end

  test "GET /hangar without a sort uses the owner's default order" do
    user = create(:user, hangar_default_sort: "rank desc")
    vehicles = %w[Alpha Bravo Charlie].map { |name| create(:vehicle, user:, name:) }
    sign_in user

    assert_api_response :get, 200 do
      assert_equal vehicles.reverse.map(&:id), parsed_body["items"].map { |item| item["id"] }
    end
  end

  test "GET /hangar with a sort ignores the owner's default order" do
    user = create(:user, hangar_default_sort: "rank desc")
    vehicles = %w[Alpha Bravo Charlie].map { |name| create(:vehicle, user:, name:) }
    sign_in user

    assert_api_response :get, 200, params: {q: {"sorts" => "name asc"}} do
      assert_equal vehicles.map(&:id), parsed_body["items"].map { |item| item["id"] }
    end
  end

  test "GET /hangar returns 400 for invalid query" do
    user = create(:user, vehicle_count: 1)
    sign_in user

    assert_api_response :get, 400, params: {q: {"foo" => "bar"}}
  end

  test "GET /hangar returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "DELETE /hangar with OAuth bearer token" do
    user = create(:user, vehicle_count: 2)

    assert_api_response :delete, 204, headers: oauth_headers_for(user, scopes: ["hangar", "hangar:write"])
  end

  test "GET /hangar with OAuth bearer token" do
    user = create(:user, vehicle_count: 3)

    assert_api_response :get, 200, headers: oauth_headers_for(user, scopes: ["hangar", "hangar:read"])
  end
end
