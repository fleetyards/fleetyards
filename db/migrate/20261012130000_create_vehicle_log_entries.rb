# frozen_string_literal: true

class CreateVehicleLogEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicle_log_entries, id: :uuid do |t|
      t.references :vehicle, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.string :title, null: false
      t.text :body
      t.datetime :logged_at, null: false
      t.boolean :public, null: false, default: false
      t.timestamps
    end

    add_index :vehicle_log_entries, [:vehicle_id, :logged_at]
  end
end
