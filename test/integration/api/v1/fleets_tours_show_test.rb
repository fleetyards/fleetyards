# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsToursShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/tours/{slug}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    get("Show Fleet Tour") do
      operationId "fleetTour"
      tags "Tours"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user"]},
        {OpenId: ["user"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::Tour
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
  end

  setup do
    Flipper.enable("tour_payouts")
    Flipper.enable("fleet_tours")

    @admin = create(:user)
    @officer = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], officers: [@officer], members: [@member])

    @tour = create(:tour, fleet: @fleet, created_by: @admin)
    create(:payout_ledger, subject: @tour)
  end

  def path_params
    {fleetSlug: @fleet.slug, slug: @tour.slug}
  end

  test "GET shows a fleet tour to a member who never joined it" do
    sign_in @member

    assert_api_response :get, 200, path_params: path_params do
      assert_equal @tour.id, parsed_body["id"]
      assert_equal @fleet.slug, parsed_body["fleet"]["slug"]
    end
  end

  test "GET shows a fleet tour to a member with no payout privileges" do
    @fleet.default_member_role.update!(resource_access: [])
    sign_in @member

    assert_api_response :get, 200, path_params: path_params do
      assert_equal @tour.id, parsed_body["id"]
    end
  end

  # What the page reads to decide whether to offer asking onto the tour, and to
  # address the withdrawal if it already did.
  test "GET names the viewer's own pending ask" do
    join_request = create(:tour_join_request, tour: @tour, user: @member)
    sign_in @member

    assert_api_response :get, 200, path_params: path_params do
      assert_equal false, parsed_body["participating"]
      assert_equal true, parsed_body["joinRequestPending"]
      assert_equal join_request.id, parsed_body["joinRequestId"]
    end
  end

  test "GET says the viewer is on the tour once they are" do
    create(:payout_participant, payout_ledger: @tour.payout_ledger, user: @member)
    sign_in @member

    assert_api_response :get, 200, path_params: path_params do
      assert_equal true, parsed_body["participating"]
      assert_nil parsed_body["joinRequestId"]
    end
  end

  test "GET returns 404 to somebody outside the fleet" do
    sign_in create(:user)

    assert_api_response :get, 404, path_params: path_params
  end

  test "GET withholds the invite token from a member who only reads" do
    sign_in @member

    assert_api_response :get, 200, path_params: path_params do
      assert_nil parsed_body["inviteToken"]
    end
  end

  # A payout manager can rotate the token, so withholding it would leave them
  # able to invalidate an invite link they cannot read or hand out.
  test "GET returns the invite token to a fleet payout manager" do
    sign_in @officer

    assert_api_response :get, 200, path_params: path_params do
      assert_equal @tour.invite_token, parsed_body["inviteToken"]
    end
  end

  # The URL claims the tour belongs to this fleet, so one that does not must
  # not resolve through it -- the page around it would name the wrong fleet.
  test "GET returns 404 for a tour of another fleet" do
    other = create(:tour, fleet: create(:fleet, admins: [@admin]), created_by: @admin)
    sign_in @admin

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug, slug: other.slug}
  end

  test "GET returns 404 for a standalone tour" do
    standalone = create(:tour, created_by: @admin)
    sign_in @admin

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug, slug: standalone.slug}
  end

  test "GET is refused when the feature is off" do
    Flipper.disable("tour_payouts")
    sign_in @admin

    assert_api_response :get, 403, path_params: path_params
  end

  test "GET returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: path_params
  end
end
