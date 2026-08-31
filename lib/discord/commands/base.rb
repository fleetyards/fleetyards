# frozen_string_literal: true

module Discord
  module Commands
    # A command turns an interaction into a message payload. No HTTP, no
    # Discord client -- the job owns the transport, so a command is a plain
    # unit test over its embed.
    class Base
      # Bit 64: only the invoking member sees the reply. Default for every
      # command, so a busy channel does not fill with bot output; a command
      # that wants a public post opts out.
      EPHEMERAL = 64

      attr_reader :options, :guild_id, :discord_user_id

      def initialize(options: {}, guild_id: nil, discord_user_id: nil)
        @options = options.to_h { |key, value| [key.to_s, value] }
        @guild_id = guild_id
        @discord_user_id = discord_user_id
      end

      def call
        raise NotImplementedError
      end

      private def option(name)
        options[name.to_s]
      end

      private def message(content: nil, embeds: nil, ephemeral: true)
        payload = {}
        payload[:content] = content if content.present?
        payload[:embeds] = embeds if embeds.present?
        payload[:flags] = EPHEMERAL if ephemeral
        payload
      end

      private def url_for_path(path)
        "https://#{Rails.configuration.app.domain}#{path}"
      end
    end
  end
end
