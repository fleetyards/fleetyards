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
#  short_description :text
#  slug              :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  fleet_id          :uuid             not null
#
# Indexes
#
#  index_fleet_squadrons_on_fleet_id_and_lower_name  (fleet_id, lower((name)::text)) UNIQUE
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
