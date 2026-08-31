# frozen_string_literal: true

module Discord
  module Commands
    class Ship < Base
      MAX_CANDIDATES = 5

      # Same colour the site uses for its primary accent, so an embed reads as
      # Fleetyards rather than as a generic bot post.
      EMBED_COLOR = 0x2d9cdb

      def call
        query = option("name").to_s.strip
        return message(content: I18n.t("discord.commands.ship.missing_query")) if query.blank?

        candidates = search(query)

        case candidates.size
        when 0 then message(content: I18n.t("discord.commands.ship.not_found", query: query))
        when 1 then message(embeds: [embed(candidates.first)], ephemeral: false)
        else disambiguate(query, candidates)
        end
      end

      # `search_cont` is the site's own matcher -- a ransack alias over name,
      # slug and manufacturer slug (`Model#ransack_alias :search`). Reusing it
      # keeps the bot and the ship list agreeing on what a name matches.
      #
      # `visible.active` is the public catalogue scope from ModelsController;
      # without it the bot would answer with unreleased and hidden models the
      # website never shows.
      private def search(query)
        scope = Model.visible.active.includes(:manufacturer)

        exact = scope.where("lower(name) = :q OR lower(slug) = :q", q: query.downcase).limit(1).to_a
        return exact if exact.any?

        scope.ransack(search_cont: query).result.ordered_by_name.limit(MAX_CANDIDATES + 1).to_a
      end

      private def disambiguate(query, candidates)
        shown = candidates.first(MAX_CANDIDATES)
        lines = shown.map { |model| "• [#{model.name}](#{page_url(model)})" }

        content = [
          I18n.t("discord.commands.ship.ambiguous", query: query, count: shown.size),
          lines.join("\n"),
          (I18n.t("discord.commands.ship.more") if candidates.size > MAX_CANDIDATES)
        ].compact.join("\n")

        message(content: content)
      end

      private def embed(model)
        {
          title: model.name,
          url: page_url(model),
          color: EMBED_COLOR,
          description: model.description.to_s.truncate(400).presence,
          fields: fields(model).map { |name, value| {name: name, value: value, inline: true} },
          thumbnail: thumbnail(model),
          footer: {text: model.manufacturer&.name}.compact_blank.presence
        }.compact_blank
      end

      private def fields(model)
        {
          I18n.t("discord.commands.ship.fields.classification") => model.classification&.humanize,
          I18n.t("discord.commands.ship.fields.size") => model.size&.humanize,
          I18n.t("discord.commands.ship.fields.crew") => crew(model),
          I18n.t("discord.commands.ship.fields.pledge_price") => model.pledge_price_label,
          I18n.t("discord.commands.ship.fields.price") => model.price_label,
          I18n.t("discord.commands.ship.fields.dimensions") => dimensions(model)
        }.compact_blank
      end

      private def crew(model)
        return model.max_crew.to_s if model.min_crew.blank? || model.min_crew == model.max_crew
        return if model.max_crew.blank?

        "#{model.min_crew}–#{model.max_crew}"
      end

      private def dimensions(model)
        [model.length_label, model.beam_label, model.height_label].compact_blank.join(" × ").presence
      end

      # rails_representation_url only builds a redirect URL -- it does not
      # process the variant here, so a cold image costs the job nothing.
      private def thumbnail(model)
        image = model.store_image
        return nil unless image.attached?

        url =
          if image.representable?
            url_helpers.rails_representation_url(
              image.representation(ActiveStorageVariants::REPRESENTATION_SIZES[:medium])
            )
          else
            url_helpers.rails_blob_url(image)
          end

        {url: url}
      end

      private def page_url(model)
        url_for_path("/ships/#{model.slug}")
      end

      private def url_helpers
        Rails.application.routes.url_helpers
      end
    end
  end
end
