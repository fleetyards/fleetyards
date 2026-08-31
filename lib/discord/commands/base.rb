# frozen_string_literal: true

module Discord
  module Commands
    # A command turns an interaction into a message payload. No HTTP, no
    # Discord client -- the job owns the transport, so a command is a plain
    # unit test over its embed.
    class Base
      # Bit 64: only the invoking member sees the reply.
      #
      # Only meaningful on an *immediate* response. Discord fixes a deferred
      # interaction's visibility at the acknowledgement and ignores flags on the
      # follow-up, so a command payload cannot carry this -- Registry.ephemeral?
      # decides it before the job runs.
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

      # No flags: this becomes a follow-up, where Discord ignores them.
      private def message(content: nil, embeds: nil)
        payload = {}
        payload[:content] = content if content.present?
        payload[:embeds] = embeds if embeds.present?
        payload
      end

      private def url_for_path(path)
        "https://#{Rails.configuration.app.domain}#{path}"
      end
    end
  end
end
