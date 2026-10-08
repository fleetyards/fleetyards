# frozen_string_literal: true

# When a guild member's own roles were last read from Discord and applied to
# the guild's join roles. A sweep works from a list of the whole guild read
# earlier, and must not apply that list over a newer read of one member --
# that would undo a role they just gained or lost.
# == Schema Information
#
# Table name: discord_member_reads
#
#  id               :uuid             not null, primary key
#  read_at          :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  discord_guild_id :string           not null
#  discord_user_id  :string           not null
#
# Indexes
#
#  index_discord_member_reads_on_guild_and_user  (discord_guild_id,discord_user_id) UNIQUE
#
class DiscordMemberRead < ApplicationRecord
  def self.record(guild_id, discord_uid, at: Time.current)
    upsert({discord_guild_id: guild_id, discord_user_id: discord_uid, read_at: at}, unique_by: %i[discord_guild_id discord_user_id])
  end

  def self.newer_than?(guild_id, discord_uid, time)
    where(discord_guild_id: guild_id, discord_user_id: discord_uid).where("read_at > ?", time).exists?
  end
end
