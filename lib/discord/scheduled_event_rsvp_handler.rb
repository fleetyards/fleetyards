# frozen_string_literal: true

module Discord
  # Handles GUILD_SCHEDULED_EVENT_USER_ADD / REMOVE events from the Discord
  # Gateway. Maps a Discord user → Fleetyards user via the existing
  # OmniauthConnection, finds the FleetEvent by the stored discord_event_id,
  # and creates / withdraws a slot-less signup. Pure ActiveRecord — no
  # Gateway plumbing — so it stays unit-testable.
  class ScheduledEventRsvpHandler
    Result = Struct.new(:status, :detail, keyword_init: true) do
      def ok? = status == :ok
      def skipped? = status == :skipped
    end

    def initialize(guild_id:, scheduled_event_id:, discord_user_id:)
      @guild_id = guild_id.to_s
      @scheduled_event_id = scheduled_event_id.to_s
      @discord_user_id = discord_user_id.to_s
    end

    def add!
      with_resolved_records do |user, event, membership|
        existing = event.fleet_event_signups
          .where(fleet_membership_id: membership.id)
          .where.not(status: "withdrawn")
          .first

        if existing
          # Already on the event (maybe in a slot already). Don't change a
          # slot-bound signup; just bump status to confirmed if it was an
          # interested / tentative event-level entry.
          if existing.fleet_event_slot_id.nil? && existing.status != "confirmed"
            existing.update!(status: "confirmed")
            Result.new(status: :ok, detail: "promoted existing event-level signup to confirmed")
          else
            Result.new(status: :skipped, detail: "already signed up")
          end
        else
          event.fleet_event_signups.create!(
            fleet_membership: membership,
            fleet_event_slot: nil,
            status: "confirmed"
          )
          Result.new(status: :ok, detail: "created event-level signup")
        end
      end
    end

    def remove!
      with_resolved_records do |_user, event, membership|
        signup = event.fleet_event_signups
          .where(fleet_membership_id: membership.id)
          .where.not(status: "withdrawn")
          .first

        if signup
          signup.withdraw!
          Result.new(status: :ok, detail: "withdrew signup #{signup.id}")
        else
          Result.new(status: :skipped, detail: "no active signup")
        end
      end
    end

    private def with_resolved_records
      user = OmniauthConnection.find_by(provider: "discord", uid: @discord_user_id)&.user
      return Result.new(status: :skipped, detail: "no FY user for discord uid #{@discord_user_id}") unless user

      event = FleetEvent.find_by(discord_event_id: @scheduled_event_id)
      return Result.new(status: :skipped, detail: "no FY event for scheduled_event_id #{@scheduled_event_id}") unless event

      setting = event.fleet&.fleet_notification_setting
      unless setting && setting.discord_guild_id == @guild_id
        return Result.new(status: :skipped, detail: "guild #{@guild_id} doesn't match fleet binding")
      end

      membership = user.fleet_memberships.find_by(fleet_id: event.fleet_id, aasm_state: "accepted")
      return Result.new(status: :skipped, detail: "user #{user.id} not an accepted member of fleet #{event.fleet_id}") unless membership

      yield(user, event, membership)
    end
  end
end
