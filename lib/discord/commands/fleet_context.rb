# frozen_string_literal: true

module Discord
  module Commands
    # Which fleet is this server? Every fleet command answers that before it can
    # do anything, and it answers "who is asking" right after -- so this carries
    # LinkedAccount rather than making each command include both.
    module FleetContext
      include LinkedAccount

      # The guild decides which fleet is meant, through the binding the fleet's
      # own notification settings already carry.
      #
      # Nothing Discord says about the caller enters here: Manage Roles in a
      # guild does not create a privilege in a fleet.
      private def guild_fleet
        return nil if guild_id.blank?

        ::FleetNotificationSetting.find_by(discord_guild_id: guild_id)&.fleet
      end
    end
  end
end
