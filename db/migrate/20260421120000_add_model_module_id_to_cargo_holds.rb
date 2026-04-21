# frozen_string_literal: true

class AddModelModuleIdToCargoHolds < ActiveRecord::Migration[7.2]
  def up
    add_column :cargo_holds, :parent_type, :string
    add_column :cargo_holds, :parent_id, :uuid

    # Migrate existing data
    execute <<~SQL
      UPDATE cargo_holds SET parent_type = 'Model', parent_id = model_id WHERE model_id IS NOT NULL
    SQL

    change_column_null :cargo_holds, :parent_type, false
    change_column_null :cargo_holds, :parent_id, false

    add_index :cargo_holds, [:parent_type, :parent_id]

    remove_index :cargo_holds, [:model_id, :max_container_size_scu]
    remove_foreign_key :cargo_holds, :models
    remove_column :cargo_holds, :model_id

    add_index :cargo_holds, [:parent_type, :parent_id, :max_container_size_scu],
      name: "index_cargo_holds_on_parent_and_max_container_size"
  end

  def down
    add_reference :cargo_holds, :model, type: :uuid, null: true, foreign_key: true

    execute <<~SQL
      UPDATE cargo_holds SET model_id = parent_id WHERE parent_type = 'Model'
    SQL

    # Remove module cargo holds that can't be migrated back
    execute <<~SQL
      DELETE FROM cargo_holds WHERE parent_type != 'Model'
    SQL

    change_column_null :cargo_holds, :model_id, false

    add_index :cargo_holds, [:model_id, :max_container_size_scu]

    remove_index :cargo_holds, [:parent_type, :parent_id, :max_container_size_scu],
      name: "index_cargo_holds_on_parent_and_max_container_size"
    remove_index :cargo_holds, [:parent_type, :parent_id]
    remove_column :cargo_holds, :parent_type
    remove_column :cargo_holds, :parent_id
  end
end
