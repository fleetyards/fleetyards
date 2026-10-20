# frozen_string_literal: true

# The catalogue row an item reward names, where one exists: a component, a
# piece of equipment or a commodity. Null for the rest -- ships handed out as
# collector loadouts, and carryables no catalogue holds.
class AddCatalogueItemToGameMissionRewards < ActiveRecord::Migration[8.1]
  def change
    add_reference :game_mission_rewards, :catalogue_item, polymorphic: true, type: :uuid, index: false
  end
end
