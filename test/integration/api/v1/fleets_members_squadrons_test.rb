# frozen_string_literal: true

require "openapi_helper"

# The roster's squadron half: the badges each member carries and the filter
# that narrows the list to one squadron. Both ride on the existing
# `/fleets/:slug/members` endpoint, which
# `Api::V1::FleetsMembersIndexTest` already documents.
class Api::V1::FleetsMembersSquadronsTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("fleet_squadrons")
    @admin = create(:user)
    @pilot = create(:user)
    @miner = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@pilot, @miner])

    @combat = create(:fleet_squadron, fleet: @fleet, name: "Combat Wing", color: "#ff0000")
    @mining = create(:fleet_squadron, fleet: @fleet, name: "Mining Division")

    @pilot_membership = @fleet.fleet_memberships.kept.find_by(user: @pilot)
    @miner_membership = @fleet.fleet_memberships.kept.find_by(user: @miner)

    create(:fleet_squadron_membership, fleet_squadron: @combat, fleet_membership: @pilot_membership)
    create(:fleet_squadron_membership, fleet_squadron: @mining, fleet_membership: @miner_membership)
  end

  def members
    JSON.parse(response.body)["items"]
  end

  def member_named(username)
    members.find { |entry| entry["username"] == username }
  end

  test "a member carries the squadrons they are in" do
    sign_in @admin

    get "/api/v1/fleets/#{@fleet.slug}/members"

    assert_response :success
    badges = member_named(@pilot.username)["squadrons"]

    assert_equal ["Combat Wing"], badges.map { |badge| badge["name"] }
    assert_equal "#ff0000", badges.first["color"]
    assert_equal "combat-wing", badges.first["slug"]
  end

  test "a member in no squadron carries an empty list" do
    sign_in @admin

    get "/api/v1/fleets/#{@fleet.slug}/members"

    assert_response :success
    assert_empty member_named(@admin.username)["squadrons"]
  end

  test "the badges are sorted by name" do
    create(:fleet_squadron_membership, fleet_squadron: @mining, fleet_membership: @pilot_membership)
    sign_in @admin

    get "/api/v1/fleets/#{@fleet.slug}/members"

    assert_response :success
    assert_equal ["Combat Wing", "Mining Division"],
      member_named(@pilot.username)["squadrons"].map { |badge| badge["name"] }
  end

  test "the roster filters to one squadron" do
    sign_in @admin

    get "/api/v1/fleets/#{@fleet.slug}/members?q[squadronSlugIn][]=combat-wing"

    assert_response :success
    assert_equal [@pilot.username], members.map { |entry| entry["username"] }
  end

  test "the roster filters to several squadrons at once" do
    sign_in @admin

    get "/api/v1/fleets/#{@fleet.slug}/members?q[squadronSlugIn][]=combat-wing&q[squadronSlugIn][]=mining-division"

    assert_response :success
    assert_equal [@miner.username, @pilot.username].sort, members.map { |entry| entry["username"] }.sort
  end

  test "the ship list narrows to a squadron" do
    Sidekiq::Testing.inline!
    pilot_ships = create(:user, vehicle_count: 3)
    create(:fleet_membership, :accepted, fleet: @fleet, user: pilot_ships).tap do |membership|
      create(:fleet_squadron_membership, fleet_squadron: @combat, fleet_membership: membership)
    end
    sign_in @admin

    get "/api/v1/fleets/#{@fleet.slug}/vehicles?q[squadronSlugIn][]=combat-wing"

    assert_response :success
    assert_equal [pilot_ships.username],
      JSON.parse(response.body)["items"].map { |entry| entry["username"] }.uniq
  ensure
    Sidekiq::Testing.fake!
  end

  # An empty squadron has to answer "no ships" rather than falling back to the
  # whole fleet, which is what a bare `where(user_id: [])` is for.
  test "the ship list is empty for a squadron nobody is in" do
    empty = create(:fleet_squadron, fleet: @fleet, name: "Reserves")
    sign_in @admin

    get "/api/v1/fleets/#{@fleet.slug}/vehicles?q[squadronSlugIn][]=#{empty.slug}"

    assert_response :success
    assert_empty JSON.parse(response.body)["items"]
  end

  test "the ship list ignores a squadron of another fleet" do
    other = create(:fleet_squadron, fleet: create(:fleet), name: "Somebody Else")
    sign_in @admin

    get "/api/v1/fleets/#{@fleet.slug}/vehicles?q[squadronSlugIn][]=#{other.slug}"

    assert_response :success
    assert_empty JSON.parse(response.body)["items"]
  end

  # The badges come off a cached fragment keyed on the membership, so the join
  # touches it. Without that the roster keeps serving yesterday's badges.
  test "adding a member to a squadron expires their roster fragment" do
    sign_in @admin

    get "/api/v1/fleets/#{@fleet.slug}/members"
    assert_response :success
    assert_empty member_named(@admin.username)["squadrons"]

    admin_membership = @fleet.fleet_memberships.kept.find_by(user: @admin)
    create(:fleet_squadron_membership, fleet_squadron: @combat, fleet_membership: admin_membership)

    get "/api/v1/fleets/#{@fleet.slug}/members"
    assert_response :success
    assert_equal ["Combat Wing"], member_named(@admin.username)["squadrons"].map { |badge| badge["name"] }
  end
end
