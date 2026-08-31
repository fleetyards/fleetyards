# frozen_string_literal: true

module Discord
  module Commands
    class Hangar < Base
      MAX_SHIPS = 10

      def call
        username = option("username").to_s.strip
        return message(content: I18n.t("discord.commands.hangar.missing_query")) if username.blank?

        user = User.find_by(normalized_username: username.downcase)

        # A private hangar and a username that does not exist get the *same*
        # answer on purpose. Distinguishing them turns the command into a probe
        # for whether an account exists.
        return message(content: I18n.t("discord.commands.hangar.not_available", username: username)) unless visible?(user)

        vehicles = user.vehicles.purchased.public
        counts = vehicles.joins(:model).group("models.name").order("count_all desc, models.name asc").count

        return message(content: I18n.t("discord.commands.hangar.empty", username: user.username)) if counts.empty?

        message(content: content_for(user, counts))
      end

      # Mirrors Public::UserPolicy#show? -- the same rule the public hangar
      # endpoint enforces, rather than a second interpretation of it.
      private def visible?(user)
        user.present? && user.public_hangar?
      end

      private def content_for(user, counts)
        shown = counts.first(MAX_SHIPS)
        lines = shown.map { |name, count| (count > 1) ? "• #{count}× #{name}" : "• #{name}" }

        [
          I18n.t("discord.commands.hangar.heading",
            username: user.username,
            url: user.public_hangar_url,
            count: counts.values.sum,
            models: counts.size),
          lines.join("\n"),
          (I18n.t("discord.commands.hangar.more", count: counts.size - shown.size) if counts.size > shown.size)
        ].compact.join("\n")
      end
    end
  end
end
