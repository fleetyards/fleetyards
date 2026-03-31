class CreateCargoHolds < ActiveRecord::Migration[7.2]
  def change
    create_table :cargo_holds, id: :uuid do |t|
      t.references :model, type: :uuid, null: false, foreign_key: true, index: true

      # Physical dimensions
      t.decimal :dimension_x, precision: 15, scale: 2, null: false
      t.decimal :dimension_y, precision: 15, scale: 2, null: false
      t.decimal :dimension_z, precision: 15, scale: 2, null: false

      # Capacity in SCU
      t.decimal :capacity_scu, precision: 15, scale: 2, null: false

      # Max container size this hold can accept
      t.integer :max_container_size_scu, null: false
      t.decimal :max_container_dimension_x, precision: 15, scale: 2
      t.decimal :max_container_dimension_y, precision: 15, scale: 2
      t.decimal :max_container_dimension_z, precision: 15, scale: 2

      # Min container size (from limits)
      t.integer :min_container_size_scu
      t.decimal :min_container_dimension_x, precision: 15, scale: 2
      t.decimal :min_container_dimension_y, precision: 15, scale: 2
      t.decimal :min_container_dimension_z, precision: 15, scale: 2

      # Metadata
      t.string :name
      t.integer :position

      t.timestamps
    end

    add_index :cargo_holds, [:model_id, :max_container_size_scu]
    add_index :cargo_holds, :capacity_scu
  end
end
