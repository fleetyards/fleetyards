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

      # Discord rejects the whole message over one embed field past this, and
      # an unanswered interaction stays on "thinking..." for good.
      FIELD_LIMIT = 1024

      # How much of a description an embed shows before pointing to the page.
      DESCRIPTION_LENGTH = 300

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

      # As many of `lines` as fit one field, and the block's line for the rest
      # -- whose own length is reserved before a line is let in. The length is
      # kept as the field grows rather than measured again per line.
      private def fit_field(lines, separator: "\n")
        shown = []
        length = 0
        lines.each_with_index do |line, index|
          rest = lines.size - index - 1
          reserve = rest.positive? ? yield(rest).length + separator.length : 0
          grown = length + (shown.empty? ? 0 : separator.length) + line.length
          break if grown + reserve > FIELD_LIMIT

          shown << line
          length = grown
        end

        hidden = lines.size - shown.size
        shown << yield(hidden) if hidden.positive?
        shown.join(separator)
      end

      private def shop_link(shop, name = shop.name)
        "[#{Markdown.escape(name)}](#{url_for_path("/shops/#{shop.slug}/")})"
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
