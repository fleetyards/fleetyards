class RemoveDuplicateIndexes < ActiveRecord::Migration[7.2]
  def change
    remove_index :cargo_hold_container_capacities, name: :index_cargo_hold_container_capacities_on_cargo_hold_id
    remove_index :cargo_holds, name: :index_cargo_holds_on_model_id
    remove_index :fleet_roles, name: :index_fleet_roles_on_fleet_id
    remove_index :imports, name: :index_imports_on_aasm_state
  end
end
