# frozen_string_literal: true

module Discord
  module Commands
    # Resolves the Discord user behind an interaction to a Fleetyards account.
    #
    # This link is the only identity the bot has. A guild permission says
    # nothing about who someone is on Fleetyards, so a member who never
    # connected their account is simply unknown here -- and that refusal is the
    # most frequently seen answer of any command that needs a person.
    module LinkedAccount
      private def linked_user
        return nil if discord_user_id.blank?

        ::OmniauthConnection.find_by(provider: "discord", uid: discord_user_id)&.user
      end

      # One answer for every command that needs a person, because it is also the
      # only refusal that is a conversion path: it names where to fix it.
      private def account_not_linked
        I18n.t("discord.commands.account_not_linked", url: url_for_path("/settings/connections"))
      end
    end
  end
end
