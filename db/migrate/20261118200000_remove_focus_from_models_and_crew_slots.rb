# frozen_string_literal: true

class RemoveFocusFromModelsAndCrewSlots < ActiveRecord::Migration[8.1]
  def change
    remove_column :models, :focus, :string, limit: 255
    remove_column :fleet_event_ships, :focus, :string
    remove_column :mission_ships, :focus, :string
  end
end
