# frozen_string_literal: true

module Discord
  module Commands
    # Mints an invite link for the guild's fleet.
    #
    # Ephemeral without exception: the token *is* the credential, and a public
    # answer hands the fleet to everyone in the channel, guests included.
    class FleetInvite < Base
      include FleetContext

      # Discord sends the choice's value, so these are the only strings that can
      # arrive. `never` is a real option rather than an omission, because "no
      # expiry" should be something someone picked.
      EXPIRES_IN = {
        "1h" => 1.hour,
        "24h" => 24.hours,
        "7d" => 7.days,
        "never" => nil
      }.freeze

      def call
        return message(content: I18n.t("discord.commands.disabled")) unless enabled?

        fleet = guild_fleet
        return message(content: I18n.t("discord.commands.fleet.not_bound")) if fleet.nil?

        user = linked_user
        return message(content: account_not_linked) if user.nil?

        invite = build_invite(fleet, user)
        return message(content: I18n.t("discord.commands.fleet.invite.not_allowed")) unless allowed?(invite, user)
        return message(content: I18n.t("discord.commands.fleet.invite.limit_too_low")) unless limit_usable?

        return message(content: I18n.t("discord.commands.fleet.invite.failed")) unless invite.save

        message(content: content_for(invite))
      end

      private def enabled?
        Flipper.enabled?(:discord_fleet_commands)
      end

      private def build_invite(fleet, user)
        fleet.fleet_invite_urls.new(
          user_id: user.id,
          limit: limit,
          expires_after: expires_after
        )
      end

      # The fleet's own privilege system decides, through the very policy the
      # HTTP endpoint authorizes against -- not a second copy of the privilege
      # list, and not anything Discord says about the caller. The policy already
      # requires an accepted, undiscarded membership.
      private def allowed?(invite, user)
        ::FleetInviteUrlPolicy.new(invite, user: user).apply(:create?)
      end

      private def limit
        value = option("limit")
        return nil if value.blank?

        value.to_i
      end

      # A limit of zero passes the model's validation and is then excluded by
      # `FleetInviteUrl.active`, so it would hand out a link that is dead on
      # arrival. Discord's own `min_value` covers the picker; this covers a
      # hand-rolled interaction.
      private def limit_usable?
        limit.nil? || limit.positive?
      end

      private def expires_after
        duration = EXPIRES_IN[option("expires_in").to_s]
        return nil if duration.nil?

        Time.zone.now + duration
      end

      # The link creates a join *request*, not a membership: FleetInviteUrl#use
      # puts the new membership straight into `requested`. Saying "they're in"
      # would be wrong.
      private def content_for(invite)
        [
          I18n.t("discord.commands.fleet.invite.heading", fleet: invite.fleet.name),
          invite.url,
          I18n.t("discord.commands.fleet.invite.needs_approval"),
          conditions(invite)
        ].compact_blank.join("\n")
      end

      private def conditions(invite)
        parts = []
        parts << I18n.t("discord.commands.fleet.invite.limit", count: invite.limit) if invite.limit.present?
        parts << I18n.t("discord.commands.fleet.invite.expires", time: invite.expires_after_label) if invite.expires_after.present?

        return nil if parts.empty?

        parts.join(" · ")
      end
    end
  end
end
