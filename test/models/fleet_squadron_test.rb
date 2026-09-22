# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: fleet_squadrons
#
#  id                :uuid             not null, primary key
#  color             :string
#  description       :text
#  name              :string           not null
#  position          :integer          default(0), not null
#  short_description :text
#  slug              :string           not null
#  team              :boolean          default(FALSE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  fleet_id          :uuid             not null
#
# Indexes
#
#  index_fleet_squadrons_on_fleet_id_and_lower_name  (fleet_id, lower((name)::text)) UNIQUE
#  index_fleet_squadrons_on_fleet_id_and_position    (fleet_id,position)
#  index_fleet_squadrons_on_fleet_id_and_slug        (fleet_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#
class FleetSquadronTest < ActiveSupport::TestCase
  setup do
    @fleet = create(:fleet)
  end

  test "generates a slug from the name" do
    squadron = create(:fleet_squadron, fleet: @fleet, name: "Alpha Wing")

    assert_equal "alpha-wing", squadron.slug
  end

  test "rejects a duplicate name in the same fleet, whatever its case" do
    create(:fleet_squadron, fleet: @fleet, name: "Alpha Wing")
    duplicate = build(:fleet_squadron, fleet: @fleet, name: "alpha wing")

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :name
  end

  # Two names the uniqueness check lets through that parameterize to one slug.
  # Without the slug validation this is a RecordNotUnique from the index, which
  # reaches the client as a 500 rather than as the validation error it is.
  test "rejects a name that collides with an existing slug" do
    create(:fleet_squadron, fleet: @fleet, name: "Alpha Wing")
    duplicate = build(:fleet_squadron, fleet: @fleet, name: "Alpha-Wing")

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :slug
  end

  test "allows the same name in another fleet" do
    create(:fleet_squadron, fleet: @fleet, name: "Alpha Wing")

    assert_predicate build(:fleet_squadron, fleet: create(:fleet), name: "Alpha Wing"), :valid?
  end

  test "accepts a three- and a six-digit hex colour and normalises the case" do
    assert_equal "#f80", create(:fleet_squadron, fleet: @fleet, color: "#F80").color
    assert_equal "#ff8800", create(:fleet_squadron, fleet: @fleet, color: " #FF8800 ").color
  end

  test "rejects a colour that is not hex" do
    squadron = build(:fleet_squadron, fleet: @fleet, color: "orange")

    assert_not squadron.valid?
    assert_includes squadron.errors.attribute_names, :color
  end

  # The card carries `description` on one line and the detail page carries the
  # long one, so only the short field is held to a line's worth.
  test "holds the short description to a line and lets the full one run" do
    assert_not build(:fleet_squadron, fleet: @fleet, short_description: "x" * 256).valid?
    assert_predicate build(:fleet_squadron, fleet: @fleet, short_description: "x" * 255), :valid?

    assert_not build(:fleet_squadron, fleet: @fleet, description: "x" * 5001).valid?
    assert_predicate build(:fleet_squadron, fleet: @fleet, description: "x" * 5000), :valid?
  end

  # The two marks are cropped to their opaque bounds on the way in; the header
  # is a photograph whose edges are the picture, so it must stay out of the
  # list however the others are changed.
  test "trims the two marks and leaves the header alone" do
    assert_equal %w[icon logo], FleetSquadron.trimmed_attachment_names
  end

  # The fleet arranges its own list, so a new squadron goes on the end of it
  # rather than into the middle by name.
  test "a new squadron is appended to the fleet's order" do
    first = create(:fleet_squadron, fleet: @fleet, name: "Zulu")
    second = create(:fleet_squadron, fleet: @fleet, name: "Alpha")

    assert_equal %w[Zulu Alpha], ordered_names(first, second)
    assert_operator second.position, :>, first.position
  end

  test "the fleet's order is what the association reads in" do
    first = create(:fleet_squadron, fleet: @fleet, name: "Alpha")
    second = create(:fleet_squadron, fleet: @fleet, name: "Bravo")

    second.update!(position: 0)

    assert_equal %w[Bravo Alpha], ordered_names(first, second)
  end

  # Only the squadrons a test made: the nested classes below add their own in
  # `setup`, and they inherit every test in this one.
  private def ordered_names(*squadrons)
    ids = squadrons.map(&:id)

    @fleet.fleet_squadrons.reload.select { |squadron| ids.include?(squadron.id) }.map(&:name)
  end

  # A member belongs to one squadron. A team is the exception, and it sits
  # outside the rule on both sides.
  class ExclusivityTest < FleetSquadronTest
    setup do
      @combat = create(:fleet_squadron, fleet: @fleet, name: "Combat")
      @mining = create(:fleet_squadron, fleet: @fleet, name: "Mining")
      @rescue = create(:fleet_squadron, fleet: @fleet, name: "Rescue", team: true)
      @membership = create(:fleet_membership, :accepted, fleet: @fleet)
    end

    test "a member holds only one squadron" do
      create(:fleet_squadron_membership, fleet_squadron: @combat, fleet_membership: @membership)

      conflicting = build(:fleet_squadron_membership, fleet_squadron: @mining, fleet_membership: @membership)

      refute_predicate conflicting, :valid?
      assert_includes conflicting.errors.details[:fleet_squadron].pluck(:error), :exclusive_conflict
    end

    test "the message names the squadron standing in the way" do
      create(:fleet_squadron_membership, fleet_squadron: @combat, fleet_membership: @membership)

      conflicting = build(:fleet_squadron_membership, fleet_squadron: @mining, fleet_membership: @membership)
      conflicting.valid?

      assert_includes conflicting.errors.full_messages.to_sentence, "Combat"
    end

    # A pilot in the Combat Wing is still free to be on the rescue rota.
    test "a team is outside the rule" do
      create(:fleet_squadron_membership, fleet_squadron: @combat, fleet_membership: @membership)

      assert_predicate build(:fleet_squadron_membership, fleet_squadron: @rescue, fleet_membership: @membership), :valid?
    end

    test "being on a team does not block a squadron" do
      create(:fleet_squadron_membership, fleet_squadron: @rescue, fleet_membership: @membership)

      assert_predicate build(:fleet_squadron_membership, fleet_squadron: @combat, fleet_membership: @membership), :valid?
    end

    test "another fleet's squadron is not in this set" do
      other_fleet = create(:fleet)
      other_membership = create(:fleet_membership, :accepted, fleet: other_fleet, user: @membership.user)
      create(:fleet_squadron_membership,
        fleet_squadron: create(:fleet_squadron, fleet: other_fleet),
        fleet_membership: other_membership)

      assert_predicate build(:fleet_squadron_membership, fleet_squadron: @combat, fleet_membership: @membership), :valid?
    end

    # Nothing would ever repair a rule that was already broken when the team
    # flag came off, and every later save of an untouched squadron would then
    # fail on a state somebody else created.
    test "a team cannot become a squadron over members who already have one" do
      create(:fleet_squadron_membership, fleet_squadron: @combat, fleet_membership: @membership)
      create(:fleet_squadron_membership, fleet_squadron: @rescue, fleet_membership: @membership)

      @rescue.team = false

      refute_predicate @rescue, :valid?
      assert_includes @rescue.errors.details[:team].pluck(:error), :conflicting_members
    end

    test "the refusal names the members it is about" do
      create(:fleet_squadron_membership, fleet_squadron: @combat, fleet_membership: @membership)
      create(:fleet_squadron_membership, fleet_squadron: @rescue, fleet_membership: @membership)

      @rescue.team = false
      @rescue.valid?

      assert_includes @rescue.errors.full_messages.to_sentence, @membership.user.username
    end

    test "a team becomes a squadron where nobody has one already" do
      create(:fleet_squadron_membership, fleet_squadron: @rescue, fleet_membership: @membership)

      @rescue.team = false

      assert_predicate @rescue, :valid?
    end

    # The check runs on the change, not on every save: a squadron that is
    # renamed must not be re-examined against a roster it already holds.
    test "a squadron saves again without re-checking its own members" do
      create(:fleet_squadron_membership, fleet_squadron: @combat, fleet_membership: @membership)

      @combat.name = "Combat Wing"

      assert_predicate @combat, :valid?
    end

    test "a discarded member is not a conflict" do
      create(:fleet_squadron_membership, fleet_squadron: @combat, fleet_membership: @membership)
      create(:fleet_squadron_membership, fleet_squadron: @rescue, fleet_membership: @membership)
      @membership.discard

      @rescue.team = false

      assert_predicate @rescue, :valid?
    end

    test "the scopes split the two kinds" do
      assert_equal %w[Combat Mining], @fleet.fleet_squadrons.exclusive.map(&:name)
      assert_equal %w[Rescue], @fleet.fleet_squadrons.teams.map(&:name)
    end
  end

  test "counts only accepted members" do
    squadron = create(:fleet_squadron, fleet: @fleet)
    accepted = create(:fleet_membership, :accepted, fleet: @fleet)
    invited = create(:fleet_membership, :invited, fleet: @fleet)
    create(:fleet_squadron_membership, fleet_squadron: squadron, fleet_membership: accepted)
    create(:fleet_squadron_membership, fleet_squadron: squadron, fleet_membership: invited)

    assert_equal 1, squadron.member_count
    assert_equal [accepted.user_id], squadron.member_user_ids
  end

  test "destroys its memberships without touching the fleet memberships" do
    squadron = create(:fleet_squadron, fleet: @fleet)
    membership = create(:fleet_membership, :accepted, fleet: @fleet)
    create(:fleet_squadron_membership, fleet_squadron: squadron, fleet_membership: membership)

    assert_difference -> { FleetSquadronMembership.count }, -1 do
      assert_no_difference -> { FleetMembership.count } do
        squadron.destroy
      end
    end
  end

  test "loses its squadron rows when the fleet membership goes" do
    squadron = create(:fleet_squadron, fleet: @fleet)
    membership = create(:fleet_membership, :accepted, fleet: @fleet)
    create(:fleet_squadron_membership, fleet_squadron: squadron, fleet_membership: membership)

    assert_difference -> { FleetSquadronMembership.count }, -1 do
      membership.destroy
    end

    assert_predicate FleetSquadron.find_by(id: squadron.id), :present?
  end

  test "goes away with its fleet" do
    squadron = create(:fleet_squadron, fleet: @fleet)

    @fleet.destroy

    assert_nil FleetSquadron.find_by(id: squadron.id)
  end
end
