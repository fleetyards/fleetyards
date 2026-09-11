# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: docks
#
#  id            :uuid             not null, primary key
#  beam          :decimal(15, 2)
#  dock_type     :integer
#  group         :string
#  height        :decimal(15, 2)
#  length        :decimal(15, 2)
#  max_ship_size :integer
#  min_ship_size :integer
#  name          :string
#  parent_type   :string           not null
#  ship_size     :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  model_id      :uuid
#  parent_id     :uuid             not null
#
# Indexes
#
#  index_docks_on_parent_type_and_parent_id  (parent_type,parent_id)
#
class DockTest < ActiveSupport::TestCase
  test "a dock belongs to a ship" do
    model = create(:model)

    assert create(:dock, parent: model).valid?
    assert_equal 1, model.docks.count
  end

  # The reason the parent is polymorphic at all: the Galaxy's medic module
  # carries a vehicle lift, and a module is not a ship.
  test "a dock belongs to a module" do
    model_module = create(:model_module)

    assert create(:dock, parent: model_module).valid?
    assert_equal 1, model_module.docks.count
  end

  # `parent_type` is a plain string column, so without the guard the admin API
  # would take any class name and a dock could hang off something that is not a
  # berth at all -- a fresh way to grow the orphans #4864 had to delete.
  test "a dock belongs to nothing else" do
    manufacturer = create(:manufacturer)

    dock = build(:dock, parent: manufacturer)

    assert_not dock.valid?
    assert_includes dock.errors[:parent_type], "is not included in the list"
  end

  test "a dock belongs to something" do
    dock = build(:dock, parent: nil)

    assert_not dock.valid?
  end

  # The create form no longer preselects a type, so nothing else may either: a
  # berth saved without one would be a landing pad or a garage by accident.
  test "a dock needs a type and a size" do
    assert_not build(:dock, dock_type: nil).valid?
    assert_not build(:dock, ship_size: nil).valid?
  end

  # Destroying the carrier takes its berths, whichever side they hang off.
  test "a module takes its docks with it" do
    model_module = create(:model_module)
    create(:dock, parent: model_module)

    assert_difference("Dock.count", -1) { model_module.destroy }
  end
end
