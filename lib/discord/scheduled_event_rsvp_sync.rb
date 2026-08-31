# frozen_string_literal: true

module Discord
  # Brings Discord's "Interested" list for one scheduled event across to
  # Fleetyards signups.
  #
  # Polling rather than the Gateway. GUILD_SCHEDULED_EVENT_USER_ADD/REMOVE are
  # Gateway-only events, and this app has no Gateway process; the REST
  # subscriber list carries the same information, survives restarts, and cannot
  # miss what happened while a worker was down. The cost is latency: an RSVP
  # lands on the next poll.
  #
  # The diff runs against DiscordEventSubscription -- a snapshot of Discord's
  # own state -- and never against the Fleetyards signups. A Fleetyards-native
  # event-level "interested" signup is indistinguishable from one a Discord
  # click produced, so diffing against signups would withdraw the answer of
  # every member who used the website and never touched Discord.
  class ScheduledEventRsvpSync
    # 20 pages of 100 is far past any real event, and stops a paging bug from
    # looping against Discord's rate limit.
    MAX_PAGES = 20

    Result = Struct.new(:added, :removed, :skipped) do
      def to_s
        "added=#{added} removed=#{removed} skipped=#{skipped}"
      end
    end

    attr_reader :guild_id, :discord_event_id

    def initialize(guild_id:, discord_event_id:, api: nil)
      @guild_id = guild_id.to_s.presence
      @discord_event_id = discord_event_id.to_s.presence
      @api = api
    end

    def runnable?
      ApiClient.configured? && guild_id.present? && discord_event_id.present?
    end

    def run!
      return nil unless runnable?

      current = fetch_subscriber_ids
      return nil if current.nil?

      known = DiscordEventSubscription.user_ids_for(discord_event_id)

      Result.new(
        added: apply_added(current - known),
        removed: apply_removed(known - current),
        skipped: 0
      )
    end

    private def apply_added(user_ids)
      user_ids.count do |user_id|
        handler_for(user_id).add!
        remember(user_id)
        true
      end
    end

    private def apply_removed(user_ids)
      user_ids.count do |user_id|
        handler_for(user_id).remove!
        forget(user_id)
        true
      end
    end

    # The snapshot records what Discord showed, not what Fleetyards made of it.
    # A subscriber with no linked Fleetyards account is still recorded, so every
    # poll does not retry them -- they simply get no signup.
    private def remember(user_id)
      DiscordEventSubscription.find_or_create_by!(
        discord_event_id: discord_event_id,
        discord_user_id: user_id
      )
    end

    private def forget(user_id)
      DiscordEventSubscription.for_event(discord_event_id)
        .where(discord_user_id: user_id)
        .delete_all
    end

    private def handler_for(user_id)
      ScheduledEventRsvpHandler.new(
        guild_id: guild_id,
        scheduled_event_id: discord_event_id,
        discord_user_id: user_id
      )
    end

    private def fetch_subscriber_ids
      ids = []
      after = nil

      MAX_PAGES.times do
        page = api.list_guild_scheduled_event_users(guild_id, discord_event_id, after: after)
        break if page.blank?

        ids.concat(page.filter_map { |entry| entry.dig("user", "id") })
        break if page.size < ApiClient::SUBSCRIBER_PAGE_SIZE

        after = ids.last
      end

      ids.uniq
    rescue ApiClient::Error => e
      # The scheduled event is gone from Discord. That is not everyone
      # un-RSVPing, so no withdrawals are issued -- the snapshot is simply
      # dropped, and a recreated event starts from an empty one.
      raise unless e.status == 404

      DiscordEventSubscription.for_event(discord_event_id).delete_all
      nil
    end

    private def api
      @api ||= ApiClient.new
    end
  end
end
