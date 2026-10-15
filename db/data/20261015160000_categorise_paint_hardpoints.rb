# frozen_string_literal: true

# Paint slots the game files leave empty were stored as `unknown`, having no
# component to name their category. Their name names it now; this sets the
# slots already loaded, and every build row of a paint slot that still reads
# `unknown` -- including older builds of a slot whose current build has a paint
# fitted.
#
# `update_all` skips the hardpoint's touch, so the hulls and components that
# hold these slots are touched here, walking up through nested slots: their
# cached payloads embed the hardpoints.
class CategorisePaintHardpoints < ActiveRecord::Migration[8.1]
  PAINTS = 90
  UNKNOWN = 999
  PAINT_SLOT = "hardpoint\\_paint%"

  def up
    slots = Hardpoint.where(source: :game_files).where("sc_name LIKE ?", PAINT_SLOT)
    rows = slots.pluck(:id, :parent_type, :parent_id)
    return if rows.empty?

    ids = rows.map(&:first)
    unknown_ids = slots.where(category: UNKNOWN).pluck(:id)
    unknown_build_ids = HardpointBuild.where(hardpoint_id: ids, category: UNKNOWN).distinct.pluck(:hardpoint_id)
    changed = unknown_ids | unknown_build_ids
    return if changed.empty?

    HardpointBuild.where(hardpoint_id: ids, category: UNKNOWN).update_all(category: PAINTS)
    Hardpoint.where(id: unknown_ids).update_all(category: PAINTS, updated_at: Time.current)

    touch_roots(rows.select { |row| changed.include?(row.first) }.map { |row| row[1..2] })
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private def touch_roots(parents)
    while parents.any?
      nested, roots = parents.partition { |type, _| type == "Hardpoint" }

      roots.group_by(&:first).each do |type, pairs|
        type.constantize.where(id: pairs.map(&:last)).update_all(updated_at: Time.current)
      end

      nested_ids = nested.map(&:last)
      Hardpoint.where(id: nested_ids).update_all(updated_at: Time.current)
      parents = Hardpoint.where(id: nested_ids).distinct.pluck(:parent_type, :parent_id)
    end
  end
end
