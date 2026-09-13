# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetContractCrewTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  COLLECTION_PATH = "/fleets/{fleetSlug}/contracts/{fleetContractSlug}/crew"
  MEMBER_PATH = "/fleets/{fleetSlug}/contracts/{fleetContractSlug}/crew/{id}"
  ACCEPT_PATH = "/fleets/{fleetSlug}/contracts/{fleetContractSlug}/crew/{id}/accept"
  DECLINE_PATH = "/fleets/{fleetSlug}/contracts/{fleetContractSlug}/crew/{id}/decline"

  api_path COLLECTION_PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "fleetContractSlug", in: :path, schema: {type: :string}

    get("List Fleet Contract Crew") do
      operationId "fleetContractCrew"
      tags "Contracts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractCrewList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    post("Join Fleet Contract Crew") do
      operationId "joinFleetContractCrew"
      tags "Contracts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractCrewMember
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path ACCEPT_PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "fleetContractSlug", in: :path, schema: {type: :string}
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    put("Accept Fleet Contract Crew Request") do
      operationId "acceptFleetContractCrew"
      tags "Contracts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractCrewMember
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path DECLINE_PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "fleetContractSlug", in: :path, schema: {type: :string}
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    put("Decline Fleet Contract Crew Request") do
      operationId "declineFleetContractCrew"
      tags "Contracts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractCrewMember
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path MEMBER_PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "fleetContractSlug", in: :path, schema: {type: :string}
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    delete("Leave Fleet Contract Crew") do
      operationId "leaveFleetContractCrew"
      tags "Contracts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractCrewMember
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_contracts")

    @officer = create(:user)
    @lead = create(:user)
    @hopeful = create(:user)
    @fleet = create(:fleet, admins: [@officer], members: [@lead, @hopeful])
    @depot = create(:fleet_inventory, fleet: @fleet)
    @contract = create(:fleet_contract, :published, fleet: @fleet, destination_fleet_inventory: @depot)
    @contract.claim_by(@lead)
  end

  test "POST asks to join" do
    sign_in @hopeful

    assert_api_response :post, 201,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug} do
      assert_equal "requested", parsed_body["state"]
      assert_equal "crew", parsed_body["role"]
    end
  end

  test "POST is refused once the crew is full" do
    @contract.update!(crew_limit: 1)
    create(:fleet_contract_assignment, :accepted, fleet_contract: @contract, user: create(:user))

    sign_in @hopeful

    assert_api_response :post, 403,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug}
  end

  test "the lead accepts a request" do
    assignment = create(:fleet_contract_assignment, fleet_contract: @contract, user: @hopeful)
    sign_in @lead

    assert_api_response :put, 200,
      api_path: ACCEPT_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug, id: assignment.id} do
      assert_equal "accepted", parsed_body["state"]
    end
  end

  test "a manager can answer for a lead who has gone quiet" do
    assignment = create(:fleet_contract_assignment, fleet_contract: @contract, user: @hopeful)
    sign_in @officer

    assert_api_response :put, 200,
      api_path: DECLINE_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug, id: assignment.id} do
      assert_equal "declined", parsed_body["state"]
    end
  end

  test "another member cannot answer somebody else's request" do
    assignment = create(:fleet_contract_assignment, fleet_contract: @contract, user: @hopeful)
    outsider = create(:user)
    create(:fleet_membership, fleet: @fleet, user: outsider, aasm_state: "accepted")

    sign_in outsider

    assert_api_response :put, 403,
      api_path: ACCEPT_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug, id: assignment.id}
  end

  test "the applicant cannot accept themselves" do
    assignment = create(:fleet_contract_assignment, fleet_contract: @contract, user: @hopeful)
    sign_in @hopeful

    assert_api_response :put, 403,
      api_path: ACCEPT_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug, id: assignment.id}
  end

  test "GET lists the crew without the people who left" do
    create(:fleet_contract_assignment, :accepted, fleet_contract: @contract, user: @hopeful)
    create(:fleet_contract_assignment, fleet_contract: @contract, user: create(:user),
      aasm_state: "withdrawn")

    sign_in @lead

    assert_api_response :get, 200,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug} do
      assert_equal 2, parsed_body.size
      assert_equal ["lead", "crew"], parsed_body.map { |row| row["role"] }
    end
  end

  test "DELETE on your own row withdraws you" do
    assignment = create(:fleet_contract_assignment, :accepted, fleet_contract: @contract, user: @hopeful)
    sign_in @hopeful

    assert_api_response :delete, 200,
      api_path: MEMBER_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug, id: assignment.id} do
      assert_equal "withdrawn", parsed_body["state"]
    end
  end

  test "DELETE by the lead removes them instead" do
    assignment = create(:fleet_contract_assignment, :accepted, fleet_contract: @contract, user: @hopeful)
    sign_in @lead

    assert_api_response :delete, 200,
      api_path: MEMBER_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug, id: assignment.id} do
      assert_equal "removed", parsed_body["state"]
    end
  end

  # The lead leaves through `release`, which puts the contract back on the board
  # and takes the crew with it. Going out through the crew endpoint would leave
  # it in progress with nobody leading.
  test "the lead cannot withdraw their own row" do
    lead_row = @contract.fleet_contract_assignments.accepted.lead.sole
    sign_in @lead

    assert_api_response :delete, 400,
      api_path: MEMBER_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug, id: lead_row.id}

    assert lead_row.reload.accepted?
    assert @contract.reload.in_progress?
  end

  test "a manager cannot remove the lead through the crew endpoint either" do
    lead_row = @contract.fleet_contract_assignments.accepted.lead.sole
    sign_in @officer

    assert_api_response :delete, 400,
      api_path: MEMBER_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug, id: lead_row.id}
  end

  # `create` find-or-initializes by user, so without the guard the lead asking
  # to join would rewrite their own row into a requested crew member.
  test "the lead asking to join does not demote their own row" do
    sign_in @lead

    assert_api_response :post, 400,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug}

    lead_row = @contract.fleet_contract_assignments.accepted.lead.sole

    assert_equal @lead.id, lead_row.user_id
  end

  test "GET needs a signed-in user" do
    assert_api_response :get, 401,
      api_path: COLLECTION_PATH,
      path_params: {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug}
  end
end
