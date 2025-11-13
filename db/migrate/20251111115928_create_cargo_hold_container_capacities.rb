class CreateCargoHoldContainerCapacities < ActiveRecord::Migration[7.2]
  def change
    create_table :cargo_hold_container_capacities, id: :uuid do |t|
      t.references :cargo_hold, type: :uuid, null: false, foreign_key: true, index: true

      # Container size in SCU (1, 2, 4, 8, 16, 24, 32)
      t.integer :container_size_scu, null: false

      # Maximum number of this container size that can fit
      t.integer :max_quantity, null: false, default: 0

      # Best orientation for this calculation
      t.string :best_orientation

      t.timestamps
    end

    add_index :cargo_hold_container_capacities,
      [:cargo_hold_id, :container_size_scu],
      unique: true,
      name: "index_cargo_hold_capacities_on_hold_and_size"

    add_index :cargo_hold_container_capacities, :container_size_scu
    add_index :cargo_hold_container_capacities, :max_quantity
  end
end
