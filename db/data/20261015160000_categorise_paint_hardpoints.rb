# frozen_string_literal: true

# Paint slots the game files leave empty were stored as `unknown`, having no
# component to name their category. Their name names it now; this sets the
# rows already loaded, and the build rows that carry the same fact.
#
# `update_all` skips the hardpoint's touch, so the hulls are touched here: their
# cached payloads embed the hardpoints.
class CategorisePaintHardpoints < ActiveRecord::Migration[8.1]
  PAINTS = 90
  UNKNOWN = 999

  def up
    hardpoints = Hardpoint.where(source: :game_files, category: UNKNOWN)
      .where("sc_name LIKE ?", "hardpoint_paint%")
    parents = hardpoints.distinct.pluck(:parent_type, :parent_id)
    ids = hardpoints.pluck(:id)
    return if ids.empty?

    HardpointBuild.where(hardpoint_id: ids, category: UNKNOWN).update_all(category: PAINTS)
    Hardpoint.where(id: ids).update_all(category: PAINTS, updated_at: Time.current)

    parents.group_by(&:first).each do |type, pairs|
      type.constantize.where(id: pairs.map(&:last)).update_all(updated_at: Time.current)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
