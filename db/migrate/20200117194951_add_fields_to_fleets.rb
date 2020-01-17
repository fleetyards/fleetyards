class AddFieldsToFleets < ActiveRecord::Migration[5.2]
  def change
    add_column :fleets, :discord, :string
    add_column :fleets, :rsi_sid, :string
    add_column :fleets, :twitch, :string
    add_column :fleets, :youtube, :string
    add_column :fleets, :ts, :string
    add_column :fleets, :homepage, :string

    add_column :fleet_memberships, :primary, :boolean, default: false
    add_column :fleet_memberships, :hide_ships, :boolean, default: false

    add_column :users, :twitch, :string
    add_column :users, :discord, :string
    add_column :users, :rsi_handle, :string
    add_column :users, :youtube, :string
    add_column :users, :homepage, :string
  end
end
