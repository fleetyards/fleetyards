# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetContractsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  COLLECTION_PATH = "/fleets/{fleetSlug}/contracts"
  MEMBER_PATH = "/fleets/{fleetSlug}/contracts/{slug}"
  PUBLISH_PATH = "/fleets/{fleetSlug}/contracts/{slug}/publish"
  CLAIM_PATH = "/fleets/{fleetSlug}/contracts/{slug}/claim"
  RELEASE_PATH = "/fleets/{fleetSlug}/contracts/{slug}/release"
  FULFIL_PATH = "/fleets/{fleetSlug}/contracts/{slug}/fulfil"
  CANCEL_PATH = "/fleets/{fleetSlug}/contracts/{slug}/cancel"
  PROGRESS_PATH = "/fleets/{fleetSlug}/contracts/{slug}/progress"

  api_path COLLECTION_PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    get("List Fleet Contracts") do
      operationId "fleetContracts"
      tags "Contracts"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::FleetContractQuery,
        style: :deepObject, explode: true, required: false
      parameter name: "page", in: :query, schema: {type: :integer}, required: false
      parameter name: "perPage", in: :query, schema: {type: :integer}, required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractsList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    post("Create Fleet Contract") do
      operationId "createFleetContract"
      tags "Contracts"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetContractInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractDetail
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path MEMBER_PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    get("Get Fleet Contract") do
      operationId "fleetContract"
      tags "Contracts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractDetail
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    patch("Update Fleet Contract") do
      operationId "updateFleetContract"
      tags "Contracts"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetContractInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractDetail
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end
    end

    delete("Delete Fleet Contract") do
      operationId "destroyFleetContract"
      tags "Contracts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful")

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path PUBLISH_PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    put("Publish Fleet Contract") do
      operationId "publishFleetContract"
      tags "Contracts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractDetail
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end
    end
  end

  api_path CLAIM_PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    put("Claim Fleet Contract") do
      operationId "claimFleetContract"
      tags "Contracts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractDetail
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path RELEASE_PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    put("Release Fleet Contract") do
      operationId "releaseFleetContract"
      tags "Contracts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractDetail
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path FULFIL_PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    put("Fulfil Fleet Contract") do
      operationId "fulfilFleetContract"
      tags "Contracts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractDetail
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path CANCEL_PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    put("Cancel Fleet Contract") do
      operationId "cancelFleetContract"
      tags "Contracts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractDetail
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end
    end
  end

  api_path PROGRESS_PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    get("Get Fleet Contract Progress") do
      operationId "fleetContractProgress"
      tags "Contracts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractProgress
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_contracts")
    Flipper.enable("fleet_logistics")
    Flipper.enable("inventory_transfers")

    @officer = create(:user)
    @member = create(:user)
    @crewmate = create(:user)
    @outsider = create(:user)
    @fleet = create(:fleet, admins: [@officer], members: [@member, @crewmate])
    @depot = create(:fleet_inventory, fleet: @fleet)
  end

  test "POST creates a draft contract" do
    sign_in @officer

    assert_api_response :post, 201,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug},
      body: {title: "Haul titanium", kind: "procurement", reward: "120000.00",
             destinationFleetInventoryId: @depot.id} do
      assert_equal "draft", parsed_body["state"]
      assert_equal @depot.id, parsed_body["destination"]["id"]
      assert_equal false, parsed_body["requiresPickup"]
    end
  end

  # The date field the schema declares as `format: date-time`. Sent explicitly
  # because a create test that omits it leaves the form free to submit a value
  # the API rejects, with the suite still green.
  test "POST accepts a deadline in RFC3339" do
    sign_in @officer

    deadline = 3.days.from_now.utc.change(usec: 0)

    assert_api_response :post, 201,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug},
      body: {title: "Haul titanium", kind: "procurement",
             destinationFleetInventoryId: @depot.id,
             deadline: deadline.iso8601} do
      assert_equal deadline, Time.zone.parse(parsed_body["deadline"])
    end
  end

  test "POST refuses a deadline that is not a timestamp" do
    sign_in @officer

    assert_api_response :post, 400,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug},
      body: {title: "Haul titanium", kind: "procurement",
             destinationFleetInventoryId: @depot.id,
             deadline: "2026-09-16T18:30"}
  end

  # The goods say what the job is, so a title is an override rather than a
  # requirement -- and an untitled contract still needs a stable slug.
  test "POST creates a contract with no title" do
    sign_in @officer

    assert_api_response :post, 201,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug},
      body: {kind: "procurement", destinationFleetInventoryId: @depot.id} do
      assert_equal "Untitled purchase", parsed_body["title"]
      assert_nil parsed_body["customTitle"]
      assert_match(/\Aprocurement-[0-9a-f]{8}\z/, parsed_body["slug"])
    end
  end

  test "the title reads back as what the contract asks for" do
    # Open, not the factory's draft: a draft is deliberately invisible to a
    # member who cannot publish it.
    contract = create(:fleet_contract, fleet: @fleet, title: nil,
      aasm_state: "open", destination_fleet_inventory: @depot)
    create(:fleet_contract_item, fleet_contract: contract,
      name: "Titanium", category: :commodity, unit: :scu, quantity: 800)

    sign_in @member

    assert_api_response :get, 200,
      api_path: MEMBER_PATH,
      path_params: {fleetSlug: @fleet.slug, slug: contract.slug} do
      assert_equal "Buy 800 SCU Titanium", parsed_body["title"]
    end
  end

  test "POST refuses a transport contract with no source" do
    sign_in @officer

    assert_api_response :post, 400,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug},
      body: {title: "Haul titanium", kind: "transport",
             destinationFleetInventoryId: @depot.id}
  end

  test "POST refuses an inventory belonging to another fleet" do
    sign_in @officer

    assert_api_response :post, 400,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug},
      body: {title: "Haul titanium", kind: "procurement",
             destinationFleetInventoryId: create(:fleet_inventory).id}
  end

  test "a member without the manage privilege cannot post one" do
    sign_in @member

    assert_api_response :post, 403,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug},
      body: {title: "Haul titanium", kind: "procurement",
             destinationFleetInventoryId: @depot.id}
  end

  test "GET lists published contracts and hides drafts from members" do
    create(:fleet_contract, :published, fleet: @fleet, destination_fleet_inventory: @depot)
    create(:fleet_contract, fleet: @fleet, destination_fleet_inventory: @depot, title: "Still a draft")

    sign_in @member

    assert_api_response :get, 200,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug} do
      assert_equal 1, parsed_body["items"].size
      assert_not_includes parsed_body["items"].map { |item| item["state"] }, "draft"
    end
  end

  test "GET shows a manager their own drafts" do
    create(:fleet_contract, fleet: @fleet, destination_fleet_inventory: @depot)

    sign_in @officer

    assert_api_response :get, 200,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug} do
      assert_equal ["draft"], parsed_body["items"].map { |item| item["state"] }
    end
  end

  # 404 rather than 403: the fleet itself is out of scope for someone who is
  # not in it, so the board does not get to say it exists.
  test "a non-member cannot see the board at all" do
    sign_in @outsider

    assert_api_response :get, 404,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug}
  end

  test "the feature flag gates the whole thing" do
    Flipper.disable("fleet_contracts")
    sign_in @officer

    assert_api_response :get, 403,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug}
  end

  test "PUT publish refuses a contract with nothing to deliver" do
    contract = create(:fleet_contract, fleet: @fleet, destination_fleet_inventory: @depot)
    sign_in @officer

    assert_api_response :put, 400,
      api_path: PUBLISH_PATH,
      path_params: {fleetSlug: @fleet.slug, slug: contract.slug}
  end

  test "PUT publish opens a contract that has lines" do
    contract = create(:fleet_contract, :with_item, fleet: @fleet, destination_fleet_inventory: @depot)
    sign_in @officer

    assert_api_response :put, 200,
      api_path: PUBLISH_PATH,
      path_params: {fleetSlug: @fleet.slug, slug: contract.slug} do
      assert_equal "open", parsed_body["state"]
    end
  end

  test "PUT claim makes the caller its lead" do
    contract = create(:fleet_contract, :published, fleet: @fleet, destination_fleet_inventory: @depot)
    sign_in @member

    assert_api_response :put, 200,
      api_path: CLAIM_PATH,
      path_params: {fleetSlug: @fleet.slug, slug: contract.slug} do
      assert_equal "in_progress", parsed_body["state"]
      lead = parsed_body["crew"].find { |row| row["role"] == "lead" }
      assert_equal @member.username, lead["user"]["username"]
    end
  end

  test "PUT claim refuses a contract somebody already took" do
    contract = create(:fleet_contract, :published, fleet: @fleet, destination_fleet_inventory: @depot)
    contract.claim_by(@officer)

    sign_in @member

    assert_api_response :put, 403,
      api_path: CLAIM_PATH,
      path_params: {fleetSlug: @fleet.slug, slug: contract.slug}
  end

  test "PUT release puts it back on the board and withdraws the crew" do
    contract = create(:fleet_contract, :published, fleet: @fleet, destination_fleet_inventory: @depot)
    contract.claim_by(@member)
    crew = create(:fleet_contract_assignment, :accepted, fleet_contract: contract, user: create(:user))

    sign_in @member

    assert_api_response :put, 200,
      api_path: RELEASE_PATH,
      path_params: {fleetSlug: @fleet.slug, slug: contract.slug} do
      assert_equal "open", parsed_body["state"]
    end

    assert crew.reload.withdrawn?
  end

  test "a crew member cannot release the contract" do
    contract = create(:fleet_contract, :published, fleet: @fleet, destination_fleet_inventory: @depot)
    contract.claim_by(@member)
    create(:fleet_contract_assignment, :accepted, fleet_contract: contract, user: @crewmate)

    sign_in @crewmate

    assert_api_response :put, 403,
      api_path: RELEASE_PATH,
      path_params: {fleetSlug: @fleet.slug, slug: contract.slug}
  end

  test "PUT fulfil is a manager's call, not a contractor's" do
    contract = create(:fleet_contract, :published, fleet: @fleet, destination_fleet_inventory: @depot)
    contract.claim_by(@member)

    sign_in @member
    assert_api_response :put, 403,
      api_path: FULFIL_PATH,
      path_params: {fleetSlug: @fleet.slug, slug: contract.slug}

    sign_in @officer
    assert_api_response :put, 200,
      api_path: FULFIL_PATH,
      path_params: {fleetSlug: @fleet.slug, slug: contract.slug} do
      assert_equal "fulfilled", parsed_body["state"]
    end
  end

  test "PUT cancel closes a contract" do
    contract = create(:fleet_contract, :published, fleet: @fleet, destination_fleet_inventory: @depot)
    sign_in @officer

    assert_api_response :put, 200,
      api_path: CANCEL_PATH,
      path_params: {fleetSlug: @fleet.slug, slug: contract.slug} do
      assert_equal "cancelled", parsed_body["state"]
    end
  end

  test "GET progress reports what the ledger holds" do
    contract = create(:fleet_contract, :published, fleet: @fleet, destination_fleet_inventory: @depot)
    contract.fleet_contract_items.destroy_all
    create(:fleet_contract_item, fleet_contract: contract,
      name: "Titanium", category: :commodity, unit: :scu, quantity: 800)

    sign_in @member

    assert_api_response :get, 200,
      api_path: PROGRESS_PATH,
      path_params: {fleetSlug: @fleet.slug, slug: contract.slug} do
      assert_equal false, parsed_body["complete"]
      assert_equal "800.0", parsed_body["lines"].first["requested"]
      assert_equal "0.0", parsed_body["lines"].first["delivered"]
    end
  end

  test "GET one is a 404 for a contract in another fleet" do
    other = create(:fleet_contract, :published)
    sign_in @officer

    assert_api_response :get, 404,
      api_path: MEMBER_PATH,
      path_params: {fleetSlug: @fleet.slug, slug: other.slug}
  end

  test "PATCH updates a contract" do
    contract = create(:fleet_contract, fleet: @fleet, destination_fleet_inventory: @depot)
    sign_in @officer

    assert_api_response :patch, 200,
      api_path: MEMBER_PATH,
      path_params: {fleetSlug: @fleet.slug, slug: contract.slug},
      body: {title: "Renamed", reward: "5000.00"} do
      assert_equal "Renamed", parsed_body["title"]
    end
  end

  test "DELETE removes a contract" do
    contract = create(:fleet_contract, fleet: @fleet, destination_fleet_inventory: @depot)
    sign_in @officer

    assert_api_response :delete, 204,
      api_path: MEMBER_PATH,
      path_params: {fleetSlug: @fleet.slug, slug: contract.slug}
  end

  test "GET with an OAuth bearer token" do
    create(:fleet_contract, :published, fleet: @fleet, destination_fleet_inventory: @depot)

    assert_api_response :get, 200,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@member, scopes: ["fleet", "fleet:read"])
  end

  test "GET needs a signed-in user" do
    assert_api_response :get, 401,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug}
  end
end
