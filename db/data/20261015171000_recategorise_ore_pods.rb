# frozen_string_literal: true

# Ore pods were spread over the cargo grid, utility and other groups, depending
# on the slot they sit in. They have a group and category of their own now; this
# moves the pods already loaded, and the build rows that hold the same pod.
#
# `update_all` skips the hardpoint's touch, so the hulls holding them are
# touched here: their cached payloads embed the hardpoints.
class RecategoriseOrePods < ActiveRecord::Migration[8.1]
  def up
    pods = Hardpoint.where(source: :game_files)
      .left_joins(:component)
      .where(
        "hardpoints.sc_name LIKE :slot OR (components.sc_key LIKE :key AND components.sc_key NOT LIKE :collapsed)",
        slot: "hardpoint\\_mining\\_pod%", key: "%mining\\_pod%", collapsed: "%\\_collapsed"
      )
      .includes(:component)
      .to_a

    # The model's own derivation, so this writes what the next load would.
    pods.each do |pod|
      pod.valid?
      next unless pod.ore_pod_group?

      attributes = {
        group: Hardpoint.groups.fetch(pod.group.to_s),
        category: Hardpoint.categories.fetch(pod.category.to_s)
      }

      builds = HardpointBuild.where(hardpoint_id: pod.id)
      builds = builds.where(component_id: pod.component_id) unless pod.sc_name.start_with?("hardpoint_mining_pod")
      builds.update_all(attributes)
      Hardpoint.where(id: pod.id).update_all(attributes.merge(updated_at: Time.current))
    end

    pods.map { |pod| [pod.parent_type, pod.parent_id] }.uniq.group_by(&:first).each do |type, pairs|
      type.constantize.where(id: pairs.map(&:last)).update_all(updated_at: Time.current)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
