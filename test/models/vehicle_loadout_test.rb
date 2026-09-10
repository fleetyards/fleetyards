# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicle_loadouts
#
#  id         :uuid             not null, primary key
#  active     :boolean          default(FALSE), not null
#  name       :string           not null
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  vehicle_id :uuid             not null
#
# Indexes
#
#  index_vehicle_loadouts_on_vehicle_id_and_name  (vehicle_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (vehicle_id => vehicles.id)
#
require "test_helper"

# A loadout is written one save at a time by its own controller, so unlike
# modules and upgrades -- destroyed and recreated wholesale on every PATCH --
# every version here is a change somebody chose to make.
class VehicleLoadoutVersioningTest < ActiveSupport::TestCase
  setup do
    @vehicle = create(:vehicle)
  end

  def versions_for(loadout)
    PaperTrail::Version.where(item_type: "VehicleLoadout", item_id: loadout.id)
  end

  test "creating and renaming a loadout each record a version" do
    loadout = @vehicle.vehicle_loadouts.create!(url: "https://www.erkul.games/loadout/abc")

    assert_equal ["create"], versions_for(loadout).pluck(:event)

    assert_difference -> { versions_for(loadout).count }, 1 do
      loadout.update!(name: "Bounty fit")
    end

    assert_equal "Bounty fit",
      versions_for(loadout).order(created_at: :desc).first.changeset["name"].last
  end

  test "a deleted loadout keeps no versions" do
    loadout = @vehicle.vehicle_loadouts.create!(url: "https://www.erkul.games/loadout/abc")
    loadout.update!(name: "Bounty fit")

    loadout.destroy!

    assert_empty versions_for(loadout)
  end

  test "destroying the ship takes its loadout versions with it" do
    loadout = @vehicle.vehicle_loadouts.create!(url: "https://www.erkul.games/loadout/abc")
    loadout.update!(name: "Bounty fit")

    @vehicle.destroy!

    assert_empty versions_for(loadout),
      "a build the owner named would outlive the account it belonged to"
  end

  test "the vehicle touch it causes records no vehicle version" do
    assert_no_difference -> { PaperTrail::Version.where(item_type: "Vehicle", item_id: @vehicle.id).count } do
      @vehicle.vehicle_loadouts.create!(url: "https://www.erkul.games/loadout/def")
    end
  end
end
