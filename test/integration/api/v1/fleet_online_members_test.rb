# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetOnlineMembersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/online-members" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    get("Fleet Online Members") do
      operationId "fleetOnlineMembers"
      tags "Fleets"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Dashboard::FleetOnlineMembersList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    UserPresence.reset!

    @reader = create(:user)
    @friend = create(:user, username: "zulu")
    @other = create(:user, username: "alpha")
    @hidden = create(:user, show_online_status: false)
    @offline = create(:user)
    @fleet = create(:fleet, admins: [@reader], members: [@friend, @other, @hidden, @offline])
    create(:friendship, :accepted, requester: @reader, addressee: @friend)

    [@reader, @friend, @other, @hidden].each { |user| UserPresence.connect(user.id, "tab-#{user.id}") }
  end

  teardown do
    UserPresence.reset!
  end

  # The reader's friends first even where the alphabet would put them last, and
  # nobody who asked not to be seen.
  test "GET online-members lists who is online, friends first" do
    sign_in @reader

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal %w[zulu alpha], parsed_body["items"].map { |row| row["username"] }
      assert_equal [true, false], parsed_body["items"].map { |row| row["friend"] }
      assert_equal 2, parsed_body["totalCount"]
    end
  end

  test "GET online-members is refused to a role that cannot read members" do
    member = create(:user)
    role = create(:fleet_role, fleet: @fleet, name: "Recruit", resource_access: [])
    create(:fleet_membership, :accepted, fleet: @fleet, user: member, fleet_role: role)

    sign_in member
    assert_api_response :get, 403, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET online-members returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end
end
