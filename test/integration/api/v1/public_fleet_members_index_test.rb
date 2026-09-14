# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicFleetMembersIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/fleets/{fleet_slug}/members" do
    parameter name: "fleet_slug", in: :path, schema: {type: :string}, description: "fleet slug"

    get("Allied Fleet Members") do
      operationId "publicFleetMembers"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::AlliedFleetMembersList
      end

      response(404, "not found unless the reader is a member or an ally") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @owner = create(:user)
    @fleet = create(:fleet, admins: [@owner], allies_fleet_members: true)
  end

  # `created_by` rather than the `members:` transient: `setup_admin_user` runs on
  # every fleet and builds a membership from that column, so a fleet created
  # without one carries an unsaved member whose user is nil -- harmless until
  # something validates or broadcasts the fleet, which two of these tests do.
  def ally_reader(fleet = @fleet)
    reader = create(:user)
    allied_fleet = create(:fleet, created_by: reader.id)
    create(:fleet_alliance, :accepted, requester: fleet, addressee: allied_fleet)
    [reader, allied_fleet]
  end

  test "an allied fleet's member can read the roster" do
    sign_in ally_reader.first

    assert_api_response :get, 200, path_params: {fleet_slug: @fleet.slug}
  end

  test "the fleet's own member can read it" do
    sign_in @owner

    assert_api_response :get, 200, path_params: {fleet_slug: @fleet.slug}
  end

  test "an unrelated signed-in user cannot" do
    sign_in create(:user)

    assert_api_response :get, 404, path_params: {fleet_slug: @fleet.slug}
  end

  test "nobody signed in cannot" do
    assert_api_response :get, 404, path_params: {fleet_slug: @fleet.slug}
  end

  test "an ally cannot read a roster the fleet has not opened" do
    closed = create(:fleet, admins: [create(:user)], allies_fleet_members: false)
    sign_in ally_reader(closed).first

    assert_api_response :get, 404, path_params: {fleet_slug: closed.slug}
  end

  test "a pending alliance is not an alliance" do
    reader = create(:user)
    allied_fleet = create(:fleet, created_by: reader.id)
    create(:fleet_alliance, requester: @fleet, addressee: allied_fleet)
    sign_in reader

    assert_api_response :get, 404, path_params: {fleet_slug: @fleet.slug}
  end

  test "an unanswered invitation to an allied fleet is not membership of it" do
    reader = create(:user)
    allied_fleet = create(:fleet, created_by: create(:user).id)
    allied_fleet.fleet_memberships.create!(user: reader, fleet_role: allied_fleet.default_member_role).invite!
    create(:fleet_alliance, :accepted, requester: @fleet, addressee: allied_fleet)
    sign_in reader

    assert_api_response :get, 404, path_params: {fleet_slug: @fleet.slug}
  end

  test "a discarded ally reads nothing" do
    reader, allied_fleet = ally_reader
    allied_fleet.discard
    sign_in reader

    assert_api_response :get, 404, path_params: {fleet_slug: @fleet.slug}
  end

  # The whole reason this endpoint has its own partial. Asserted over the key
  # set rather than by sampling, so a field added to the fleet's own member
  # payload cannot arrive here unnoticed.
  test "the payload carries nothing the fleet's own member payload does" do
    sign_in ally_reader.first

    assert_api_response :get, 200, path_params: {fleet_slug: @fleet.slug}

    member = parsed_body["items"].first

    # `avatar` is absent rather than empty when nothing is attached, so the
    # assertion is that no key outside this set can appear -- not that all of
    # them do.
    assert_empty member.keys - %w[avatar hidden id role username]
    assert_equal %w[hidden id role username].sort, (member.keys & %w[hidden id role username]).sort

    %w[
      discord youtube twitch guilded rsiHandle homepage latitude longitude
      currentSystemCode lastActiveAt hangarUpdatedAt discordProfileUrl
      citizenidProfileUrl nickname fleetSlug userId
    ].each do |leaked|
      assert_not_includes member.keys, leaked
    end
  end

  test "a member who hides themselves keeps their place and loses their name" do
    hidden_member = create(:user, hide_owner: true)
    @fleet.fleet_memberships.create!(
      user: hidden_member, fleet_role: @fleet.default_member_role,
      aasm_state: :accepted, accepted_at: Time.zone.now
    )
    sign_in ally_reader.first

    assert_api_response :get, 200, path_params: {fleet_slug: @fleet.slug}

    rows = parsed_body["items"]
    hidden_row = rows.find { |row| row["hidden"] }

    assert_equal 2, rows.size
    assert_not_nil hidden_row
    assert_not_includes hidden_row.keys, "username"
    assert_not_includes rows.filter_map { |row| row["username"] }, hidden_member.username
  end
end
