# frozen_string_literal: true

class CreateFleetDiscordRoleHolders < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_discord_role_holders, id: :uuid do |t|
      t.references :fleet, type: :uuid, null: false, foreign_key: true, index: false
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end

    add_index :fleet_discord_role_holders, %i[fleet_id user_id], unique: true
  end
end
