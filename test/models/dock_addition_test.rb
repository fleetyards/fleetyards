# frozen_string_literal: true

require "test_helper"

# A ship named as fitting a berth, beyond what the berth's class covers.
# == Schema Information
#
# Table name: dock_additions
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  dock_id    :uuid             not null
#  model_id   :uuid             not null
#
# Indexes
#
#  index_dock_additions_on_dock_id               (dock_id)
#  index_dock_additions_on_dock_id_and_model_id  (dock_id,model_id) UNIQUE
#  index_dock_additions_on_model_id              (model_id)
#
# Foreign Keys
#
#  fk_rails_...  (dock_id => docks.id)
#  fk_rails_...  (model_id => models.id)
#
class DockAdditionTest < ActiveSupport::TestCase
  test "a berth names the ships its class does not cover" do
    dock = create(:dock)
    arrow = create(:model, name: "Arrow")
    create(:dock_addition, dock:, model: arrow)

    assert_equal [arrow], dock.reload.added_models
  end

  test "a ship is named once per berth" do
    dock = create(:dock)
    model = create(:model)
    create(:dock_addition, dock:, model:)

    assert_not build(:dock_addition, dock:, model:).valid?
  end

  test "the same ship can be named on another berth" do
    model = create(:model)
    create(:dock_addition, dock: create(:dock), model:)

    assert build(:dock_addition, dock: create(:dock), model:).valid?
  end

  test "a berth takes its additions with it" do
    dock = create(:dock)
    create(:dock_addition, dock:)

    assert_difference -> { DockAddition.count }, -1 do
      dock.destroy
    end
  end

  # The entry survives a class change rather than being recomputed: it is a
  # statement about that ship, made by somebody who looked.
  test "an addition is kept when the berth's class changes" do
    dock = create(:dock, ship_size: :small)
    create(:dock_addition, dock:)

    dock.update!(ship_size: :large)

    assert_equal 1, dock.reload.additions.count
  end
end
