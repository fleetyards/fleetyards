class SetupShips < ActiveRecord::Migration
  def change
    create_table :ships do |t|
      t.string :name
      t.string :slug
      t.string :rsi_name
      t.integer :manufacturer_id
      t.integer :ship_role_id
      t.text :description
      t.string :length
      t.string :beam
      t.string :height
      t.string :mass
      t.string :cargo
      t.string :crew
      t.string :image
      t.boolean :enabled, default: false

      t.timestamps
    end

    create_table :ship_roles do |t|
      t.string :name
      t.string :rsi_name
      t.string :slug

      t.timestamps
    end

    create_table :manufacturers do |t|
      t.string :name
      t.string :rsi_name
      t.string :slug
      t.string :rsi_slug
      t.string :logo

      t.timestamps
    end

    create_table :worker_states do |t|
      t.string :name
      t.boolean :running, default: false
      t.datetime :last_run_start
      t.datetime :last_run_end

      t.timestamps
    end
  end
end
