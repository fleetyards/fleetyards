# frozen_string_literal: true

# The values a contract states for the `~mission(Token)` placeholders in its
# title and description, keyed by token.
class AddPlaceholderValuesToGameMissions < ActiveRecord::Migration[8.1]
  def change
    %i[game_missions game_mission_builds].each do |table|
      add_column table, :placeholder_values, :jsonb
    end
  end
end
