# frozen_string_literal: true

# Modules and salvage filler stations shared the `other` group with the cargo
# grids, and salvage storage had no group at all. Modules have a group of their
# own now, and the filler stations and storage share a salvage one; this moves
# the slots already loaded, and the build rows holding the same component.
#
# `update_all` skips the hardpoint's touch, so the hulls holding them are
# touched here: their cached payloads embed the hardpoints.
class SplitModulesAndSalvageFromCargo < ActiveRecord::Migration[8.1]
  OTHER = 9

  def up
    storage = Component.where(component_type: "SalvageInternalStorage").select(:id)
    slots = Hardpoint.where(source: :game_files)
      .merge(Hardpoint.where(group: OTHER).or(Hardpoint.where(component_id: storage)))
      .includes(:component)
      .to_a

    # The model's own derivation, so this writes what the next load would.
    moved = slots.select do |slot|
      slot.valid?
      next false if slot.other_group?

      attributes = {
        group: Hardpoint.groups.fetch(slot.group.to_s),
        category: Hardpoint.categories.fetch(slot.category.to_s)
      }
      HardpointBuild.where(hardpoint_id: slot.id, component_id: slot.component_id).update_all(attributes)
      Hardpoint.where(id: slot.id).update_all(attributes.merge(updated_at: Time.current))
    end

    moved.map { |slot| [slot.parent_type, slot.parent_id] }.uniq.group_by(&:first).each do |type, pairs|
      type.constantize.where(id: pairs.map(&:last)).update_all(updated_at: Time.current)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
