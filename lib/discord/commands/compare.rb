# frozen_string_literal: true

require "discord/commands/model_lookup"

module Discord
  module Commands
    class Compare < Base
      include ModelLookup

      EMBED_COLOR = 0x2d9cdb

      def call
        first_query = option("first").to_s.strip
        second_query = option("second").to_s.strip

        if first_query.blank? || second_query.blank?
          return message(content: I18n.t("discord.commands.compare.missing_query"))
        end

        first, answer = resolve_model(first_query)
        return answer if first.nil?

        second, answer = resolve_model(second_query)
        return answer if second.nil?

        if first.id == second.id
          return message(content: I18n.t("discord.commands.compare.same_ship", ship: first.name))
        end

        message(embeds: [embed(first, second)])
      end

      # A Discord embed has no table, so each stat becomes one field holding
      # both values. Deliberately not the website's comparison table: that has
      # dozens of rows across ten sections, and an embed caps out long before it
      # -- the link is there for the full picture.
      private def embed(first, second)
        {
          title: I18n.t("discord.commands.compare.title", first: first.name, second: second.name),
          url: compare_url(first, second),
          color: EMBED_COLOR,
          description: [
            "[#{first.name}](#{model_page_url(first)})",
            "[#{second.name}](#{model_page_url(second)})"
          ].join(" · "),
          fields: rows(first, second).map { |name, values| {name: name, value: values, inline: true} }
        }.compact_blank
      end

      # The compare page keeps its selection in the query string through
      # useFilters, as repeated `models[]` entries.
      private def compare_url(first, second)
        url_for_path("/compare/?#{{models: [first.slug, second.slug]}.to_query}")
      end

      private def rows(first, second)
        stats(first).keys.each_with_object({}) do |key, rows|
          left = stats(first)[key]
          right = stats(second)[key]
          next if left.blank? && right.blank?

          rows[key] = "#{first.name}: #{left.presence || "—"}\n#{second.name}: #{right.presence || "—"}"
        end
      end

      private def stats(model)
        @stats ||= {}
        @stats[model.id] ||= {
          I18n.t("discord.commands.ship.fields.classification") => model.classification&.humanize,
          I18n.t("discord.commands.ship.fields.size") => model.size&.humanize,
          I18n.t("discord.commands.ship.fields.crew") => crew(model),
          I18n.t("discord.commands.ship.fields.cargo") => cargo(model),
          I18n.t("discord.commands.ship.fields.pledge_price") => model.pledge_price_label,
          I18n.t("discord.commands.ship.fields.dimensions") => dimensions(model)
        }
      end

      private def crew(model)
        return model.max_crew.to_s if model.min_crew.blank? || model.min_crew == model.max_crew
        return if model.max_crew.blank?

        "#{model.min_crew}–#{model.max_crew}"
      end

      private def cargo(model)
        return if model.cargo.blank? || model.cargo.zero?

        "#{model.cargo.to_i} SCU"
      end

      private def dimensions(model)
        [model.length_label, model.beam_label, model.height_label].compact_blank.join(" × ").presence
      end
    end
  end
end
