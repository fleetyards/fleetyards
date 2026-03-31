class DropModelAdditions < ActiveRecord::Migration[7.2]
  def up
    drop_table :model_additions
  end

  def down
    create_table :model_additions do |t|
      t.references :model, null: false, index: true
      t.timestamps

      t.decimal :beam, precision: 15, scale: 2, default: 0.0, null: false
      t.decimal :length, precision: 15, scale: 2, default: 0.0, null: false
      t.decimal :height, precision: 15, scale: 2, default: 0.0, null: false
      t.decimal :mass, precision: 15, scale: 2, default: 0.0, null: false
      t.decimal :cargo, precision: 15, scale: 2
      t.decimal :net_cargo, precision: 15, scale: 2
      t.decimal :scm_speed, precision: 15, scale: 2, default: 0.0, null: false
      t.decimal :afterburner_speed, precision: 15, scale: 2, default: 0.0, null: false
      t.decimal :cruise_speed, precision: 15, scale: 2, default: 0.0, null: false
      t.integer :min_crew
      t.integer :max_crew
      t.decimal :price, precision: 15, scale: 2, default: 0.0, null: false
    end
  end
end
