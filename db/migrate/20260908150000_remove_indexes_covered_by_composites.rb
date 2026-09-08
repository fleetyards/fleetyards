# frozen_string_literal: true

# Every index here is the leading prefix of a wider index on the same table, so
# it answers nothing the wider one does not. Most are the single-column index
# `add_reference` creates, later joined by a composite that starts on the same
# column.
class RemoveIndexesCoveredByComposites < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_index :cargo_holds, column: [:parent_type, :parent_id],
      name: "index_cargo_holds_on_parent_type_and_parent_id", algorithm: :concurrently
    remove_index :commodity_builds, column: :commodity_id,
      name: "index_commodity_builds_on_commodity_id", algorithm: :concurrently
    remove_index :component_builds, column: :component_id,
      name: "index_component_builds_on_component_id", algorithm: :concurrently
    remove_index :equipment_builds, column: :equipment_id,
      name: "index_equipment_builds_on_equipment_id", algorithm: :concurrently
    remove_index :fleet_event_admins, column: :fleet_event_id,
      name: "index_fleet_event_admins_on_fleet_event_id", algorithm: :concurrently
    remove_index :fleet_event_ship_models, column: :fleet_event_ship_id,
      name: "index_fleet_event_ship_models_on_ship", algorithm: :concurrently
    remove_index :fleet_event_ships, column: :fleet_event_team_id,
      name: "index_fleet_event_ships_on_fleet_event_team_id", algorithm: :concurrently
    remove_index :fleet_event_signups, column: :fleet_event_id,
      name: "index_fleet_event_signups_on_fleet_event_id", algorithm: :concurrently
    remove_index :fleet_event_slots, column: [:slottable_type, :slottable_id],
      name: "index_fleet_event_slots_on_slottable_type_and_slottable_id", algorithm: :concurrently
    remove_index :fleet_event_teams, column: :fleet_event_id,
      name: "index_fleet_event_teams_on_fleet_event_id", algorithm: :concurrently
    remove_index :item_price_snapshots, column: [:item_type, :item_id],
      name: "index_item_price_snapshots_on_item", algorithm: :concurrently
    remove_index :mission_ship_models, column: :mission_ship_id,
      name: "index_mission_ship_models_on_mission_ship_id", algorithm: :concurrently
    remove_index :mission_ships, column: :mission_team_id,
      name: "index_mission_ships_on_mission_team_id", algorithm: :concurrently
    remove_index :mission_slots, column: [:slottable_type, :slottable_id],
      name: "index_mission_slots_on_slottable_type_and_slottable_id", algorithm: :concurrently
    remove_index :mission_teams, column: :mission_id,
      name: "index_mission_teams_on_mission_id", algorithm: :concurrently
    remove_index :model_build_changes, column: :model_id,
      name: "index_model_build_changes_on_model_id", algorithm: :concurrently
    remove_index :model_builds, column: :model_id,
      name: "index_model_builds_on_model_id", algorithm: :concurrently
    remove_index :model_sales, column: :model_id,
      name: "index_model_sales_on_model_id", algorithm: :concurrently
    remove_index :models, column: :manufacturer_id,
      name: "index_models_on_manufacturer_id", algorithm: :concurrently
    remove_index :vehicle_loadout_hardpoints, column: :vehicle_loadout_id,
      name: "index_vehicle_loadout_hardpoints_on_vehicle_loadout_id", algorithm: :concurrently
    remove_index :vehicle_loadouts, column: :vehicle_id,
      name: "index_vehicle_loadouts_on_vehicle_id", algorithm: :concurrently
  end
end
