# frozen_string_literal: true

# Mining pods were named `cargogrid` by their slot name, which read their ore as
# cargo space. They take their component's category now, as every other slot
# does; this sets the pods already loaded and their build rows.
#
# `update_all` skips the hardpoint's touch, so the hulls holding them are
# touched here: their cached payloads embed the hardpoints.
class RecategoriseMiningPods < ActiveRecord::Migration[8.1]
  CARGOGRID = 92

  def up
    pods = Hardpoint.where(source: :game_files, category: CARGOGRID)
      .where("sc_name LIKE ?", "hardpoint\\_mining\\_pod%")
      .includes(:component)

    # The model's own derivation, so this writes what the next load would.
    pods.each do |pod|
      pod.valid?
      category = Hardpoint.categories.fetch(pod.category.to_s)

      HardpointBuild.where(hardpoint_id: pod.id, category: CARGOGRID).update_all(category:)
      Hardpoint.where(id: pod.id).update_all(category:, updated_at: Time.current)
    end

    pods.map { |pod| [pod.parent_type, pod.parent_id] }.uniq.group_by(&:first).each do |type, pairs|
      type.constantize.where(id: pairs.map(&:last)).update_all(updated_at: Time.current)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
