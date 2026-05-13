# frozen_string_literal: true

class AddEventColumnsToFleets < ActiveRecord::Migration[7.2]
  def change
    add_column :fleets, :default_timezone, :string, null: false, default: "UTC"
    add_column :fleets, :calendar_feed_token, :string
    add_index :fleets, :calendar_feed_token, unique: true
  end
end
