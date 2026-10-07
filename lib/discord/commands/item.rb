# frozen_string_literal: true

module Discord
  module Commands
    # One command for the game-file catalogues, rather than one per catalogue:
    # someone asking for a P4-AR neither knows nor cares which catalogue we file
    # it under. Names resolve through the same resolver as an inline `[*Name*]`
    # in a text, so the bot finds the item the site would for the same words,
    # and a suggestion's value is that token -- a picked one always resolves.
    class Item < Base
      include ActionView::Helpers::NumberHelper

      CATALOGUES = %w[component equipment commodity blueprint].freeze
      MAX_CANDIDATES = 5
      EMBED_COLOR = 0x2d9cdb
      DESCRIPTION_LENGTH = 300

      PAGES = {
        "component" => "components",
        "equipment" => "equipment",
        "commodity" => "commodities",
        "blueprint" => "blueprints"
      }.freeze

      def self.autocomplete(option, value)
        return [] unless option == "name"

        ::Catalogue::TokenResolver.new.search(value, within: CATALOGUES).map do |match|
          {name: "#{match.name} · #{type_label(prefix_for(match))}", value: match.token}
        end
      end

      def self.prefix_for(match)
        ::Catalogue::TokenResolver::CATALOGUES.key(match.type.constantize)
      end

      def self.type_label(prefix)
        I18n.t("discord.commands.item.types.#{prefix}")
      end

      def call
        query = option("name").to_s.strip
        return message(content: I18n.t("discord.commands.item.missing_query")) if query.blank?

        matches = resolved(query)
        return message(content: I18n.t("discord.commands.item.not_found", query: query)) if matches.empty?
        return candidate_list(query, matches) unless matches.one?

        prefix = self.class.prefix_for(matches.first)
        record = ::Catalogue::TokenResolver.listed(prefix).find_by(slug: matches.first.slug)
        return message(content: I18n.t("discord.commands.item.not_found", query: query)) if record.nil?

        message(embeds: [embed(prefix, record)])
      end

      # The token first, as a picked suggestion sends it; a name typed by hand
      # that names no one item falls back to what the suggestions would offer.
      private def resolved(query)
        resolver = ::Catalogue::TokenResolver.new
        exact = resolver.resolve([query]).select { |match| catalogued?(match) }
        return exact if exact.any?

        resolver.search(query, within: CATALOGUES).select { |match| catalogued?(match) }
      end

      private def catalogued?(match)
        CATALOGUES.include?(self.class.prefix_for(match))
      end

      private def candidate_list(query, matches)
        shown = matches.first(MAX_CANDIDATES)
        lines = shown.map do |match|
          prefix = self.class.prefix_for(match)
          "• [#{match.name}](#{page_url(prefix, match.slug)}) · #{self.class.type_label(prefix)}"
        end

        content = [
          I18n.t("discord.commands.item.ambiguous", query: query, count: shown.size),
          lines.join("\n"),
          (I18n.t("discord.commands.item.more") if matches.size > MAX_CANDIDATES)
        ].compact.join("\n")

        message(content: content)
      end

      private def embed(prefix, record)
        {
          author: {name: [self.class.type_label(prefix), category(prefix, record)].compact_blank.join(" · ")},
          title: record.name,
          url: page_url(prefix, record.slug),
          color: EMBED_COLOR,
          description: description(prefix, record),
          fields: send(:"#{prefix}_fields", record).compact_blank.map { |name, value| {name: name, value: value, inline: true} },
          thumbnail: thumbnail((prefix == "blueprint") ? record.craftable : record),
          footer: {text: record.try(:manufacturer)&.name}.compact_blank.presence
        }.compact_blank
      end

      private def category(prefix, record)
        case prefix
        when "component"
          if record.category.present?
            I18n.t("filter.component.category.catalogue_items.#{record.category}",
              default: [:"filter.component.category.items.#{record.category}", record.category.to_s.titleize])
          end
        when "equipment" then record.equipment_type_label
        when "commodity"
          I18n.t("filter.commodity.commodity_type.items.#{record.commodity_type}", default: record.commodity_type.to_s.titleize) if record.commodity_type.present?
        when "blueprint"
          type = record.craftable_type
          I18n.t("discord.commands.item.types.#{type.underscore}", default: type) if type.present?
        end
      end

      private def description(prefix, record)
        return blueprint_description(record) if prefix == "blueprint"

        record.description.to_s.truncate(DESCRIPTION_LENGTH).presence
      end

      # What a recipe makes and takes, each linked, as the site's card lists them.
      private def blueprint_description(record)
        craftable = record.craftable
        materials = record.materials

        [
          (I18n.t("discord.commands.item.makes", item: craftable_link(craftable)) if craftable.present?),
          (I18n.t("discord.commands.item.materials", items: materials.map { |commodity| "[#{commodity.name}](#{page_url("commodity", commodity.slug)})" }.join(", ")) if materials.any?)
        ].compact.join("\n").presence
      end

      private def craftable_link(craftable)
        prefix = ::Catalogue::TokenResolver::CATALOGUES.key(craftable.class)
        listed = prefix && ::Catalogue::TokenResolver.listed(prefix).exists?(slug: craftable.slug)

        listed ? "[#{craftable.name}](#{page_url(prefix, craftable.slug)})" : craftable.name
      end

      private def component_fields(record)
        {
          I18n.t("discord.commands.item.fields.size") => record.size&.to_s,
          I18n.t("discord.commands.item.fields.grade") => record.grade_label,
          I18n.t("discord.commands.item.fields.class") => record.item_class_label,
          I18n.t("discord.commands.item.fields.buy") => price(record.sell_price)
        }
      end

      private def equipment_fields(record)
        {
          I18n.t("discord.commands.item.fields.size") => record.size&.to_s,
          I18n.t("discord.commands.item.fields.grade") => record.grade&.to_s,
          I18n.t("discord.commands.item.fields.slot") => record.slot_label,
          I18n.t("discord.commands.item.fields.buy") => price(record.sell_price)
        }
      end

      # Prices are stored from the shop's side: what a shop sells at is what the
      # reader pays to buy, so the two columns trade places on the way out, as
      # they do on the site.
      private def commodity_fields(record)
        {
          I18n.t("discord.commands.item.fields.buy") => price(record.sell_price),
          I18n.t("discord.commands.item.fields.sell") => price(record.buy_price)
        }
      end

      private def blueprint_fields(record)
        {
          I18n.t("discord.commands.item.fields.craft_time") => craft_time(record.craft_time),
          I18n.t("discord.commands.item.fields.slots") => record.slot_count&.to_s
        }
      end

      private def price(value)
        return if value.blank?

        "#{number_with_delimiter(number_with_precision(value, precision: 2, strip_insignificant_zeros: true))} aUEC"
      end

      private def craft_time(seconds)
        return if seconds.blank?

        ActiveSupport::Duration.build(seconds.to_i).parts.map { |unit, amount| "#{amount}#{unit.to_s.first}" }.join(" ")
      end

      # Discord cannot draw a vector, and most game icons are SVGs with no raster
      # variant, so those leave the embed without a picture rather than broken.
      private def thumbnail(record)
        image = %i[store_image icon].filter_map { |name| record.try(name) }.find(&:attached?)
        return nil unless image&.representable?
        return nil if ActiveStorageVariants::VECTOR_CONTENT_TYPES.include?(image.content_type)

        {url: url_helpers.rails_representation_url(image.representation(ActiveStorageVariants::REPRESENTATION_SIZES[:medium]))}
      end

      private def page_url(prefix, slug)
        url_for_path("/catalogue/#{PAGES.fetch(prefix)}/#{slug}/")
      end

      private def url_helpers
        Rails.application.routes.url_helpers
      end
    end
  end
end
