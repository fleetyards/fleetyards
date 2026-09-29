# frozen_string_literal: true

require "test_helper"

class LinkPreviewTest < ActiveSupport::TestCase
  setup do
    @fleet = create(:fleet, name: "Ember Guard")
  end

  test "a published event every member sees names itself" do
    event = build(:fleet_event, :open, fleet: @fleet, title: "Mining night")

    assert_equal "Mining night", LinkPreview.for_fleet_event(event).title
  end

  test "an event for officers or a squadron reads as one of the fleet's" do
    %w[officers squadron].each do |visibility|
      event = build(:fleet_event, :open, fleet: @fleet, title: "Secret op", visibility:)

      assert_equal "Fleet event in Ember Guard", LinkPreview.for_fleet_event(event).title
    end
  end

  test "a draft event reads as one of the fleet's" do
    event = build(:fleet_event, fleet: @fleet, title: "Not yet")

    assert_equal "Fleet event in Ember Guard", LinkPreview.for_fleet_event(event).title
  end

  test "an event without a cover shows the fleet's logo" do
    attach(@fleet.logo)
    event = build(:fleet_event, :open, fleet: @fleet)

    assert_equal @fleet.logo, LinkPreview.for_fleet_event(event).image
  end

  test "an event's own cover wins over the logo" do
    attach(@fleet.logo)
    event = build(:fleet_event, :open, fleet: @fleet)
    attach(event.cover_image)

    assert_equal event.cover_image, LinkPreview.for_fleet_event(event).image
  end

  test "a restricted event shows the logo, never its cover" do
    event = build(:fleet_event, :open, fleet: @fleet, visibility: "officers")
    attach(event.cover_image)

    assert_nil LinkPreview.for_fleet_event(event).image
  end

  test "a published contract for all members names itself" do
    contract = build(:fleet_contract, fleet: @fleet, title: "Ore run", aasm_state: "open")

    assert_equal "Ore run", LinkPreview.for_fleet_contract(contract).title
  end

  test "a squadron or draft contract reads as one of the fleet's" do
    squadron = build(:fleet_contract, fleet: @fleet, title: "Ore run", aasm_state: "open", visibility: :squadron_only)
    draft = build(:fleet_contract, fleet: @fleet, title: "Ore run")

    assert_equal "Contract in Ember Guard", LinkPreview.for_fleet_contract(squadron).title
    assert_equal "Contract in Ember Guard", LinkPreview.for_fleet_contract(draft).title
  end

  test "a fleet's tour names itself" do
    tour = build(:tour, :for_fleet, fleet: @fleet, title: "Stanton loop")

    assert_equal "Stanton loop", LinkPreview.for_tour(tour).title
  end

  test "a standalone tour reads as a tour" do
    tour = build(:tour, title: "Private loop")

    assert_equal "Tour", LinkPreview.for_tour(tour).title
  end

  test "an invite link names the tour it joins" do
    tour = build(:tour, title: "Private loop")

    assert_equal "Join Private loop", LinkPreview.for_tour(tour, via_invite: true).title
  end

  private def attach(attachment)
    attachment.attach(io: file_fixture("test.png").open, filename: "test.png", content_type: "image/png")
  end
end
