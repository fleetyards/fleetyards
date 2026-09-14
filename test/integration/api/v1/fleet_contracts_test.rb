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
      # Not a ransack filter: "am I on this" is a question about the caller,
      # not about a column.
      parameter name: "mine", in: :query, schema: {type: :boolean}, required: false
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

  # A contract with nothing to deliver cannot be published, so the create form
  # collects the goods with it rather than sending the author to a second form
  # to add them.
  test "POST creates a contract with its goods in one request" do
    sign_in @officer

    assert_api_response :post, 201,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug},
      body: {kind: "procurement", reward: "120000.00",
             destinationFleetInventoryId: @depot.id,
             items: [
               {name: "Titanium", category: "commodity", unit: "scu", quantity: "800.0",
                quality: 500, qualityMatch: "at_least"},
               {name: "Agricium", category: "commodity", unit: "scu", quantity: "200.0"}
             ]} do
      assert_equal 2, parsed_body["itemsCount"]
    end

    contract = FleetContract.order(:created_at).last

    assert_equal %w[Agricium Titanium], contract.fleet_contract_items.map(&:name).sort
    assert_equal 500, contract.fleet_contract_items.find_by(name: "Titanium").quality
  end

  # Nested saving is one transaction, so a line the model refuses takes the
  # contract with it -- a half-built contract is worse than none.
  test "POST refuses the whole contract when one of its goods is invalid" do
    sign_in @officer

    assert_difference -> { FleetContract.count }, 0 do
      post "/api/v1/fleets/#{@fleet.slug}/contracts",
        params: {kind: "procurement", reward: "1.00",
                 destinationFleetInventoryId: @depot.id,
                 items: [{name: "", category: "commodity", unit: "scu", quantity: "800.0"}]},
        as: :json

      assert_response :bad_request
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
  # A member's own board: what they are working, which is the accepted seats --
  # a withdrawn request is not work they are on.
  test "GET mine lists only the contracts the caller works" do
    mine = create(:fleet_contract, :in_progress, fleet: @fleet, destination_fleet_inventory: @depot)
    create(:fleet_contract_assignment, :accepted, fleet_contract: mine, user: @crewmate)

    somebody_elses = create(:fleet_contract, :in_progress, fleet: @fleet,
      destination_fleet_inventory: @depot)
    create(:fleet_contract_assignment, :accepted, fleet_contract: somebody_elses, user: @member)

    withdrawn = create(:fleet_contract, :in_progress, fleet: @fleet,
      destination_fleet_inventory: @depot)
    create(:fleet_contract_assignment, fleet_contract: withdrawn, user: @crewmate,
      aasm_state: "withdrawn")

    sign_in @crewmate

    get "/api/v1/fleets/#{@fleet.slug}/contracts", params: {mine: true}, as: :json

    assert_response :success
    assert_equal [mine.slug], parsed_body["items"].map { |item| item["slug"] }
  end

  test "GET mine narrows to a state like any other board" do
    done = create(:fleet_contract, :published, fleet: @fleet, destination_fleet_inventory: @depot)
    done.update!(aasm_state: "fulfilled")
    create(:fleet_contract_assignment, :accepted, fleet_contract: done, user: @crewmate)

    running = create(:fleet_contract, :in_progress, fleet: @fleet,
      destination_fleet_inventory: @depot)
    create(:fleet_contract_assignment, :accepted, fleet_contract: running, user: @crewmate)

    sign_in @crewmate

    get "/api/v1/fleets/#{@fleet.slug}/contracts",
      params: {mine: true, q: {state_in: ["fulfilled"]}}, as: :json

    assert_response :success
    assert_equal [done.slug], parsed_body["items"].map { |item| item["slug"] }
  end

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

  # Published, a contract is an offer somebody may already be working to, so
  # what it pays and what it asks for stop moving.
  test "PATCH refuses a contract that is no longer a draft" do
    contract = create(:fleet_contract, :published, fleet: @fleet,
      destination_fleet_inventory: @depot)
    sign_in @officer

    patch "/api/v1/fleets/#{@fleet.slug}/contracts/#{contract.slug}",
      params: {reward: "999999.00"}, as: :json

    assert_response :forbidden
    refute_equal 999_999.to_d, contract.reload.reward
  end

  test "its goods are closed with it" do
    contract = create(:fleet_contract, :published, fleet: @fleet,
      destination_fleet_inventory: @depot)
    sign_in @officer

    assert_difference -> { FleetContractItem.count }, 0 do
      post "/api/v1/fleets/#{@fleet.slug}/contracts/#{contract.slug}/items",
        params: {name: "Titanium", category: "commodity", unit: "scu", quantity: "5.0"},
        as: :json

      assert_response :forbidden
    end
  end

  # Cancelling has to reach a contract that is already out there, which is the
  # rule editing no longer follows.
  test "PUT cancel still reaches a published contract" do
    contract = create(:fleet_contract, :published, fleet: @fleet,
      destination_fleet_inventory: @depot)
    sign_in @officer

    put "/api/v1/fleets/#{@fleet.slug}/contracts/#{contract.slug}/cancel", as: :json

    assert_response :success
    assert_equal "cancelled", contract.reload.aasm_state
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
