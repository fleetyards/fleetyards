# frozen_string_literal: true

# When a guild member's roles were last read from Discord and applied to a
# fleet's join role -- alone, or as part of a list of the whole guild. Every
# path applies under the member's lock and skips a read older than this, so
# two sweeps, or a sweep and an update, end on what Discord answered last.
# == Schema Information
#
# Table name: discord_member_reads
#
#  id              :uuid             not null, primary key
#  read_at         :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  discord_user_id :string           not null
#  fleet_id        :uuid             not null
#
# Indexes
#
#  index_discord_member_reads_on_fleet_id_and_discord_user_id  (fleet_id,discord_user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#
class DiscordMemberRead < ApplicationRecord
  belongs_to :fleet

  def self.record(fleet, discord_uid, at: Time.current)
    upsert(
      {fleet_id: fleet.id, discord_user_id: discord_uid, read_at: at},
      unique_by: %i[fleet_id discord_user_id],
      on_duplicate: Arel.sql("read_at = GREATEST(discord_member_reads.read_at, EXCLUDED.read_at), updated_at = EXCLUDED.updated_at")
    )
  end

  def self.newer_than?(fleet, discord_uid, time)
    where(fleet:, discord_user_id: discord_uid).where("read_at > ?", time).exists?
  end
end
