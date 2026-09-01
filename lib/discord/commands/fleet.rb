# frozen_string_literal: true

module Discord
  module Commands
    class Fleet < Base
      include LinkedAccount

      EMBED_COLOR = 0x2d9cdb

      def call
        fleet = resolve_fleet
        return message(content: I18n.t("discord.commands.fleet.not_bound")) if fleet.nil?
        return message(content: I18n.t("discord.commands.fleet.not_allowed", fleet: fleet.name)) unless allowed?(fleet)

        message(embeds: [embed(fleet)])
      end

      # The guild the command came from decides which fleet is meant, through
      # the binding the fleet's own notification settings already carry.
      private def resolve_fleet
        return nil if guild_id.blank?

        ::FleetNotificationSetting.find_by(discord_guild_id: guild_id)&.fleet
      end

      # A member of the fleet may always see it; anyone else only if the fleet
      # chose to be public. Sharing a Discord server is not membership -- a
      # server can have guests, and the fleet's own privacy setting is the only
      # thing that speaks for it.
      private def allowed?(fleet)
        fleet.public_fleet? || member?(fleet)
      end

      private def member?(fleet)
        user = linked_user
        return false if user.blank?

        user.fleet_memberships.exists?(fleet_id: fleet.id, aasm_state: "accepted")
      end

      private def embed(fleet)
        {
          title: fleet.name,
          url: url_for_path("/fleets/#{fleet.slug}"),
          color: EMBED_COLOR,
          description: fleet.description.to_s.truncate(300).presence,
          fields: fields(fleet).map { |name, value| {name: name, value: value, inline: true} }
        }.compact_blank
      end

      private def fields(fleet)
        {
          I18n.t("discord.commands.fleet.fields.members") => member_count(fleet).to_s,
          I18n.t("discord.commands.fleet.fields.ships") => fleet.vehicles.count.to_s,
          I18n.t("discord.commands.fleet.fields.models") => fleet.models.distinct.count.to_s,
          I18n.t("discord.commands.fleet.fields.upcoming_events") => upcoming_events(fleet).to_s
        }.compact_blank
      end

      private def member_count(fleet)
        fleet.fleet_memberships.where(aasm_state: "accepted").count
      end

      private def upcoming_events(fleet)
        fleet.fleet_events.where(archived_at: nil).where(starts_at: Time.current..).count
      end
    end
  end
end
