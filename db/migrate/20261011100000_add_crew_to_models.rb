# frozen_string_literal: true

class AddCrewToModels < ActiveRecord::Migration[8.1]
  # The ship matrix now gives one crew figure where it used to give a range, and
  # the game files only ever gave one. Where a range survives, the upper end is
  # the one the game agrees with.
  def up
    add_column :models, :crew, :integer
    add_column :models, :rsi_crew, :integer
    add_column :model_builds, :crew, :integer

    execute <<~SQL.squish
      UPDATE models
      SET crew = COALESCE(max_crew, min_crew),
        rsi_crew = COALESCE(rsi_max_crew, rsi_min_crew)
    SQL
  end

  def down
    remove_column :model_builds, :crew
    remove_column :models, :rsi_crew
    remove_column :models, :crew
  end
end
