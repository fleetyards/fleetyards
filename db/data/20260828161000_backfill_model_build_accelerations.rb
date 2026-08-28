# frozen_string_literal: true

# Fills the two acceleration facts for builds already in the table.
#
# Computed rather than copied: there is nothing to copy from -- the columns this
# replaces held seconds, and they are gone. Newton's second law over what the
# export already gave us, so this needs no export access, only the loadout the
# last load wrote.
class BackfillModelBuildAccelerations < ActiveRecord::Migration[8.1]
  def up
    Model.where(in_game: true).find_each do |model|
      figures = model.accelerations_from_hardpoints
      next if figures.blank?

      model.update_columns(figures)
      model.builds.update_all(figures)
    end
  end

  def down
    ModelBuild.update_all(main_acceleration: nil, retro_acceleration: nil)
    Model.update_all(main_acceleration: nil, retro_acceleration: nil)
  end
end
