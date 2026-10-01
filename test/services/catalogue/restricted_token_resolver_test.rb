# frozen_string_literal: true

require "test_helper"

module Catalogue
  class RestrictedTokenResolverTest < ActiveSupport::TestCase
    setup do
      Flipper.enable("fleet_contracts")
      Flipper.enable("fleet_mission_builder")

      @admin = create(:user)
      @member = create(:user)
      @fleet = create(:fleet, fid: "MARU", admins: [@admin], members: [@member])
      @contract = create(:fleet_contract, :published, fleet: @fleet, created_by: @admin, title: "Salvage Run")
      @event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Weekly Mining")
    end

    def resolved(reader, *tokens, fleet_reader: reader)
      TokenResolver.new(reader:, fleet_reader:).resolve(tokens).to_h do |match|
        [match.token, [match.type, match.slug, match.fleet_slug]]
      end
    end

    def searched(reader, query)
      TokenResolver.new(reader:).search(query).map(&:token)
    end

    test "resolves a contract and an event for a member, by FID and title in any case" do
      assert_equal(
        {
          "contract:maru/salvage run" => ["FleetContract", @contract.slug, @fleet.slug],
          "event:MARU/Weekly Mining" => ["FleetEvent", @event.slug, @fleet.slug]
        },
        resolved(@member, "contract:maru/salvage run", "event:MARU/Weekly Mining")
      )
    end

    test "names the record by its stored title" do
      match = TokenResolver.new(reader: @member).resolve(["contract:MARU/salvage run"]).sole

      assert_equal "Salvage Run", match.name
    end

    test "resolves nothing for a signed-out reader" do
      assert_empty resolved(nil, "contract:MARU/Salvage Run", "event:MARU/Weekly Mining")
    end

    test "resolves nothing for a reader outside the fleet" do
      assert_empty resolved(create(:user), "contract:MARU/Salvage Run", "event:MARU/Weekly Mining")
    end

    test "resolves nothing for a member whose request is not accepted yet" do
      requested = create(:user)
      create(:fleet_membership, :requested, fleet: @fleet, user: requested)

      assert_empty resolved(requested, "contract:MARU/Salvage Run", "event:MARU/Weekly Mining")
    end

    test "resolves nothing in a fleet that was disbanded" do
      @fleet.update_columns(discarded_at: Time.current)

      assert_empty resolved(@member, "contract:MARU/Salvage Run", "event:MARU/Weekly Mining")
    end

    test "resolves nothing for a member whose role cannot read contracts or events" do
      role = create(:fleet_role, fleet: @fleet, name: "Recruit", resource_access: [])
      recruit = create(:user)
      create(:fleet_membership, :accepted, fleet: @fleet, user: recruit, fleet_role: role)

      assert_empty resolved(recruit, "contract:MARU/Salvage Run", "event:MARU/Weekly Mining")
    end

    test "keeps a draft contract to those who could publish it" do
      draft = create(:fleet_contract, fleet: @fleet, created_by: @admin, title: "Secret Haul")

      assert_empty resolved(@member, "contract:MARU/Secret Haul")
      assert_equal({"contract:MARU/Secret Haul" => ["FleetContract", draft.slug, @fleet.slug]}, resolved(@admin, "contract:MARU/Secret Haul"))
    end

    test "keeps a squadron's contract and event to that squadron and the managers" do
      squadron = create(:fleet_squadron, fleet: @fleet)
      inside = create(:user)
      membership = create(:fleet_membership, :accepted, fleet: @fleet, user: inside)
      create(:fleet_squadron_membership, fleet_squadron: squadron, fleet_membership: membership)
      contract = create(:fleet_contract, :published, fleet: @fleet, created_by: @admin, title: "Squad Haul",
        visibility: :squadron_only, fleet_squadrons: [squadron])
      event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Squad Op",
        visibility: "squadron", fleet_squadrons: [squadron])
      tokens = ["contract:MARU/Squad Haul", "event:MARU/Squad Op"]
      expected = {
        "contract:MARU/Squad Haul" => ["FleetContract", contract.slug, @fleet.slug],
        "event:MARU/Squad Op" => ["FleetEvent", event.slug, @fleet.slug]
      }

      assert_empty resolved(@member, *tokens)
      assert_equal expected, resolved(inside, *tokens)
      assert_equal expected, resolved(@admin, *tokens)
    end

    test "resolves nothing while the feature is off for the fleet" do
      Flipper.disable("fleet_contracts")
      Flipper.disable("fleet_mission_builder")

      assert_empty resolved(@member, "contract:MARU/Salvage Run", "event:MARU/Weekly Mining")
    end

    test "resolves nothing in an unsubscribed fleet once subscriptions are enforced" do
      Flipper.enable("fleet_subscriptions")

      assert_empty resolved(@member, "contract:MARU/Salvage Run", "event:MARU/Weekly Mining")

      create(:fleet_subscription, fleet: @fleet)

      assert_equal 2, resolved(@member, "contract:MARU/Salvage Run", "event:MARU/Weekly Mining").size
    end

    test "resolves no fleet token without a fleet reader" do
      assert_empty resolved(@member, "contract:MARU/Salvage Run", "event:MARU/Weekly Mining", fleet_reader: nil)
    end

    # The writer may have meant the one this reader cannot see.
    test "leaves a title two of the fleet's events carry unresolved, even when the reader sees one" do
      create(:fleet_event, fleet: @fleet, created_by: @admin, title: "Weekly Mining", visibility: "squadron",
        fleet_squadrons: [create(:fleet_squadron, fleet: @fleet)])

      assert_empty resolved(@member, "event:MARU/Weekly Mining")
    end

    test "ignores a token without a fleet, a title or a known FID" do
      assert_empty resolved(@member, "contract:Salvage Run", "contract:MARU/", "event:NOPE/Weekly Mining", "contract:/Salvage Run")
    end

    test "does not reach another fleet's record through its own FID" do
      other = create(:fleet, fid: "OTHR", members: [@member])
      create(:fleet_contract, :published, fleet: other, created_by: @admin, title: "Other Run")

      assert_empty resolved(@member, "contract:MARU/Other Run")
    end

    test "links a user whose hangar the reader may see" do
      create(:user, username: "OpenHangar", public_hangar: true)
      friend = create(:user, username: "FriendsOnly", public_hangar: false, friends_hangar: true)
      create(:friendship, :accepted, requester: @member, addressee: friend)
      closed = create(:user, username: "Closed", public_hangar: false, friends_hangar: false)
      create(:friendship, :accepted, requester: @member, addressee: closed)

      assert_equal(
        {"user:openhangar" => ["User", "OpenHangar", nil], "user:FriendsOnly" => ["User", "FriendsOnly", nil]},
        resolved(@member, "user:openhangar", "user:FriendsOnly", "user:Closed", "user:nobody")
      )
      assert_equal({"user:openhangar" => ["User", "OpenHangar", nil]}, resolved(nil, "user:openhangar", "user:FriendsOnly"))
    end

    test "does not open a friends-only hangar to a fleet-mate who is no friend" do
      create(:user, username: "Mate", public_hangar: false, friends_hangar: true).tap do |mate|
        create(:fleet_membership, :accepted, fleet: @fleet, user: mate)
      end

      assert_empty resolved(@member, "user:Mate")
    end

    test "offers the reader's contracts and events with the fleet in their token" do
      assert_equal ["contract:MARU/Salvage Run"], searched(@member, "salv")
      assert_equal ["event:MARU/Weekly Mining"], searched(@member, "Weekly")
    end

    test "narrows a search by its prefix and by the FID written into it" do
      create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Salvage Night")
      other = create(:fleet, fid: "OTHR", members: [@member])
      create(:fleet_event, :open, fleet: other, created_by: @admin, title: "Salvage Day")

      assert_equal ["event:MARU/Salvage Night", "event:OTHR/Salvage Day"].sort, searched(@member, "event:salv").sort
      assert_equal ["event:OTHR/Salvage Day"], searched(@member, "event:othr/salv")
    end

    test "offers nothing the reader may not open, nor a title the fleet carries twice" do
      create(:fleet_contract, fleet: @fleet, created_by: @admin, title: "Salvage Draft")
      create_list(:fleet_event, 2, :open, fleet: @fleet, created_by: @admin, title: "Salvage Twice")

      assert_equal ["contract:MARU/Salvage Run"], searched(@member, "salv")
      assert_includes searched(@admin, "salv"), "contract:MARU/Salvage Draft"
      assert_empty searched(nil, "salv")
      assert_empty searched(create(:user), "salv")
    end

    test "offers the reader's friends and fleet-mates, and nobody else" do
      friend = create(:user, username: "pilot-friend")
      create(:friendship, :accepted, requester: friend, addressee: @member)
      create(:user, username: "pilot-stranger")
      pending = create(:user, username: "pilot-pending")
      create(:friendship, requester: pending, addressee: @member)
      mate = create(:user, username: "pilot-mate")
      create(:fleet_membership, :accepted, fleet: @fleet, user: mate)

      assert_equal ["user:pilot-mate", "user:pilot-friend"].sort, searched(@member, "user:pilot").sort
      assert_empty searched(nil, "user:pilot")
    end

    test "offers nobody whose hangar the writer may not open" do
      create(:fleet_membership, :accepted, fleet: @fleet,
        user: create(:user, username: "pilot-private", public_hangar: false, friends_hangar: true))
      create(:fleet_membership, :accepted, fleet: @fleet, user: create(:user, username: "pilot-open"))

      assert_equal ["user:pilot-open"], searched(@member, "user:pilot")
    end

    test "offers fleet-mates only to a fleet reader" do
      friend = create(:user, username: "pilot-friend")
      create(:friendship, :accepted, requester: friend, addressee: @member)
      create(:fleet_membership, :accepted, fleet: @fleet, user: create(:user, username: "pilot-mate"))

      found = TokenResolver.new(reader: @member, fleet_reader: nil).search("user:pilot").map(&:token)

      assert_equal ["user:pilot-friend"], found
    end

    # The policy filters after the database has picked its rows, so a page of
    # rows the reader may not open must not leave them with nothing.
    test "offers a visible contract behind more hidden ones than one page holds" do
      create_list(:fleet_contract, TokenResolver::SEARCH_LIMIT, fleet: @fleet, created_by: @admin) do |contract, index|
        contract.update!(title: "Cargo #{index}")
      end
      create(:fleet_contract, :published, fleet: @fleet, created_by: @admin, title: "Cargo Run Extended")

      assert_equal ["contract:MARU/Cargo Run Extended"], searched(@member, "contract:cargo")
    end

    test "searches a title with a slash in it without its FID" do
      create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Ops 1/2")

      assert_equal ["event:MARU/Ops 1/2"], searched(@member, "event:ops 1/2")
      assert_equal ["event:MARU/Ops 1/2"], searched(@member, "event:maru/ops 1/2")
    end

    test "offers no title a token cannot hold" do
      create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Mining *Night*")

      assert_empty searched(@member, "event:mining night")
      assert_equal ["event:MARU/Weekly Mining"], searched(@member, "event:mining")
    end

    test "resolves a split series to the half still running" do
      series = create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Weekly Op",
        starts_at: Time.zone.parse("2026-05-14 20:00 UTC"), timezone: "UTC",
        recurring: true, recurrence_interval: "weekly", recurrence_every: 1)

      travel_to Time.zone.parse("2026-05-20 12:00 UTC")
      successor = FleetEvents::SeriesSplit.new(series, "2026-06-04").call

      # Until the first half has had its last occurrence, both are running.
      assert_empty resolved(@member, "event:MARU/Weekly Op")

      travel_to Time.zone.parse("2026-06-05 12:00 UTC")

      assert_equal({"event:MARU/Weekly Op" => ["FleetEvent", successor.slug, @fleet.slug]},
        resolved(@member, "event:MARU/Weekly Op"))
      assert_includes searched(@member, "event:weekly op"), "event:MARU/Weekly Op"
    end

    test "passes over a finished, cancelled or archived namesake" do
      create(:fleet_event, fleet: @fleet, created_by: @admin, title: "Weekly Mining",
        starts_at: 2.days.ago, ends_at: 2.days.ago + 2.hours)
      create(:fleet_event, :cancelled, fleet: @fleet, created_by: @admin, title: "Weekly Mining")
      create(:fleet_event, fleet: @fleet, created_by: @admin, title: "Weekly Mining", archived_at: Time.current)

      assert_equal({"event:MARU/Weekly Mining" => ["FleetEvent", @event.slug, @fleet.slug]},
        resolved(@member, "event:MARU/Weekly Mining"))
      assert_equal ["event:MARU/Weekly Mining"], searched(@member, "event:weekly")
    end

    test "leaves a title two running events carry unresolved, and unoffered" do
      create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Weekly Mining")

      assert_empty resolved(@member, "event:MARU/Weekly Mining")
      assert_empty searched(@member, "event:weekly")
    end

    test "resolves nothing when the one running namesake is hidden from the reader" do
      @event.update!(starts_at: 2.days.ago, ends_at: 2.days.ago + 2.hours)
      create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Weekly Mining", visibility: "squadron",
        fleet_squadrons: [create(:fleet_squadron, fleet: @fleet)])

      assert_empty resolved(@member, "event:MARU/Weekly Mining")
      assert_empty searched(@member, "event:weekly")
    end
  end
end
