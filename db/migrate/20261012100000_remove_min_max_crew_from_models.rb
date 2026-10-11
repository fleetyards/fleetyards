# frozen_string_literal: true

# `crew` and `rsi_crew` replaced all four. The release before this one stopped
# selecting them (`ignored_columns`), so the containers still serving it are
# unaffected by the pre-deploy migration.
class RemoveMinMaxCrewFromModels < ActiveRecord::Migration[8.1]
  def change
    remove_column :models, :min_crew, :integer
    remove_column :models, :max_crew, :integer
    remove_column :models, :rsi_min_crew, :integer
    remove_column :models, :rsi_max_crew, :integer
  end
end
