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
      with_resolved_records do |_user, event, membership|
        existing = event.fleet_event_signups
          .where(fleet_membership_id: membership.id)
          .where.not(status: "withdrawn")
          .first

        # Discord scheduled events expose only a single "Interested" RSVP —
        # never a stronger commitment. We translate that 1:1 to FY's
        # "interested" status when the member has no signup yet, and leave
        # any existing signup alone so the Discord click can't downgrade
        # or override choices already made on Fleetyards.
        if existing
          Result.new(status: :skipped, detail: "already signed up (#{existing.status})")
        else
          event.fleet_event_signups.create!(
            fleet_membership: membership,
            fleet_event_slot: nil,
            status: "interested"
          )
          Result.new(status: :ok, detail: "created event-level interested signup")
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
