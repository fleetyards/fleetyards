# frozen_string_literal: true

class CreateDiscordMemberReads < ActiveRecord::Migration[8.1]
  def change
    create_table :discord_member_reads, id: :uuid do |t|
      t.string :discord_guild_id, null: false
      t.string :discord_user_id, null: false
      t.datetime :read_at, null: false
      t.timestamps
    end

    add_index :discord_member_reads, %i[discord_guild_id discord_user_id], unique: true, name: "index_discord_member_reads_on_guild_and_user"
  end
end
