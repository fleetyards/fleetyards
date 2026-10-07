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

      # Same colour the site uses for its primary accent, so an embed reads as
      # Fleetyards rather than as a generic bot post.
      EMBED_COLOR = 0x2d9cdb

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

      # Prices are aUEC, the in-game currency the UEX snapshot quotes.
      private def uec(value)
        return if value.blank?

        rounded = ActiveSupport::NumberHelper.number_to_rounded(value, precision: 2, strip_insignificant_zeros: true,
          delimiter: I18n.t("number.format.delimiter"))
        "#{rounded} aUEC"
      end

      private def url_for_path(path)
        "https://#{Rails.configuration.app.domain}#{path}"
      end

      # The first of `attachments` Discord can draw: an image, and not a vector.
      # Most game icons are SVGs with no raster variant, so those are passed
      # over rather than sent as a broken picture.
      #
      # rails_representation_url only builds a redirect URL -- it does not
      # process the variant here, so a cold image costs the job nothing.
      private def thumbnail(*attachments)
        image = attachments.compact.find do |attachment|
          attachment.attached? && attachment.image? && ActiveStorageVariants::VECTOR_CONTENT_TYPES.exclude?(attachment.content_type)
        end
        return nil if image.nil?

        url =
          if image.representable?
            url_helpers.rails_representation_url(image.representation(ActiveStorageVariants::REPRESENTATION_SIZES[:medium]))
          else
            url_helpers.rails_blob_url(image)
          end

        {url: url}
      end

      private def url_helpers
        Rails.application.routes.url_helpers
      end
    end
  end
end
