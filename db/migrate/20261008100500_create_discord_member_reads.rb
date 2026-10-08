# frozen_string_literal: true

class CreateDiscordMemberReads < ActiveRecord::Migration[8.1]
  def change
    create_table :discord_member_reads, id: :uuid do |t|
      t.references :fleet, type: :uuid, null: false, foreign_key: true, index: false
      t.string :discord_user_id, null: false
      t.datetime :read_at, null: false
      t.timestamps
    end

    add_index :discord_member_reads, %i[fleet_id discord_user_id], unique: true
  end
end
