# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetContractPayoutsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/contracts/{fleetContractSlug}/payouts" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "fleetContractSlug", in: :path, schema: {type: :string}

    post("Open a payout ledger on a fulfilled fleet contract") do
      operationId "createFleetContractPayoutLedger"
      tags "Payouts"
      consumes "application/json"
      produces "application/json"

      request_body schema: ::V1::Schemas::Inputs::PayoutLedgerCreateInput, required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Payouts::PayoutLedger
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    get("Show the payout ledger of a fleet contract") do
      operationId "fleetContractPayoutLedger"
      tags "Payouts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::PayoutLedger
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "no ledger yet") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("tour_payouts")
    Flipper.enable("fleet_tours")
    Flipper.enable("fleet_contracts")

    @admin = create(:user)
    @lead = create(:user)
    @crew = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@lead, @crew, @member])
    @contract = create(:fleet_contract, :fulfilled, fleet: @fleet, created_by: @admin, reward: 90_000)
    create(:fleet_contract_assignment, :lead, fleet_contract: @contract, user: @lead)
    create(:fleet_contract_assignment, :accepted, fleet_contract: @contract, user: @crew)
  end

  def path_params
    {fleetSlug: @fleet.slug, fleetContractSlug: @contract.slug}
  end

  test "POST seeds the fleet as payer and pays the reward to the contractors" do
    sign_in @admin

    assert_api_response :post, 201, path_params: path_params do
      assert_equal "FleetContract", parsed_body["subjectType"]
      assert_equal "90000.0", parsed_body["totalIncome"]
      # The fleet payer is on the ledger but divides nothing.
      assert_equal 2, parsed_body["participantsCount"]
      assert_equal "2.0", parsed_body["totalWeight"]

      ledger = PayoutLedger.find(parsed_body["id"])
      assert_equal @fleet.id, ledger.payout_participants.find_by!(user_id: nil).fleet_id
      assert_equal [@lead.id, @crew.id].sort, ledger.payout_participants.where.not(user_id: nil).pluck(:user_id).sort

      shares = ledger.settlement.balances.reject { |balance| balance.participant.fleet_id }.map(&:share)
      assert_equal [45_000, 45_000], shares
    end
  end

  test "POST is refused while the contract is still being worked" do
    @contract.update_columns(aasm_state: "in_progress", fulfilled_at: nil)
    sign_in @admin

    assert_api_response :post, 403, path_params: path_params
  end

  test "POST is refused for a contractor" do
    sign_in @lead

    assert_api_response :post, 403, path_params: path_params
  end

  test "POST is refused when fleet contracts are off for the fleet" do
    Flipper.disable("fleet_contracts")
    sign_in @admin

    assert_api_response :post, 403, path_params: path_params
  end

  test "POST returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: path_params
  end

  test "GET shows the ledger to a contractor" do
    ledger = create(:payout_ledger, subject: @contract)
    create(:payout_participant, payout_ledger: ledger, user: @crew)
    sign_in @crew

    assert_api_response :get, 200, path_params: path_params do
      assert_equal ledger.id, parsed_body["id"]
    end
  end

  test "GET returns 404 before a ledger exists" do
    sign_in @admin

    assert_api_response :get, 404, path_params: path_params
  end

  test "GET returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: path_params
  end

  # A payout privilege must not reveal a contract the reader cannot open --
  # a squadron-only one outside their squadron, say.
  test "GET is refused to a payout reader who cannot see the contract" do
    create(:payout_ledger, subject: @contract)
    FleetContractPolicy.any_instance.stubs(:show?).returns(false)
    sign_in @member

    assert_api_response :get, 403, path_params: path_params
  end
end
