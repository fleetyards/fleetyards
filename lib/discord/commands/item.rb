# frozen_string_literal: true

module Discord
  module Commands
    # One command for the game-file catalogues, rather than one per catalogue:
    # someone asking for a P4-AR neither knows nor cares which catalogue we file
    # it under. ItemLookup resolves the name.
    class Item < Base
      include ItemLookup

      CATALOGUES = %w[component equipment commodity blueprint].freeze
      DESCRIPTION_LENGTH = 300

      def call
        prefix, found = lookup_item
        return found if prefix.nil?

        message(embeds: [embed(prefix, found)])
      end

      private def embed(prefix, record)
        {
          author: {name: [ItemLookup.type_label(prefix), category(prefix, record)].compact_blank.join(" · ")},
          title: record.name,
          url: item_page_url(prefix, record.slug),
          color: EMBED_COLOR,
          description: description(prefix, record),
          fields: send(:"#{prefix}_fields", record).compact_blank.map { |name, value| {name: name, value: value, inline: true} },
          thumbnail: thumbnail(*images((prefix == "blueprint") ? record.craftable : record)),
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
          # Off the output the embed links, which the served build names; the
          # row's column holds whichever source loaded last.
          type = record.craftable&.class&.name
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
        listed = materials.any? ? ::Catalogue::TokenResolver.listed("commodity").where(id: materials.map(&:id)).pluck(:id).to_set : Set.new
        material_links = materials.map do |commodity|
          listed.include?(commodity.id) ? item_link(commodity.name, "commodity", commodity.slug) : Markdown.escape(commodity.name)
        end

        [
          (I18n.t("discord.commands.item.makes", item: craftable_link(craftable)) if craftable.present?),
          (I18n.t("discord.commands.item.materials", items: material_links.join(", ")) if materials.any?)
        ].compact.join("\n").presence
      end

      private def craftable_link(craftable)
        prefix = ::Catalogue::TokenResolver::CATALOGUES.key(craftable.class)
        listed = prefix && ::Catalogue::TokenResolver.listed(prefix).exists?(slug: craftable.slug)

        listed ? item_link(craftable.name, prefix, craftable.slug) : Markdown.escape(craftable.name)
      end

      private def component_fields(record)
        {
          I18n.t("discord.commands.item.fields.size") => record.size&.to_s,
          I18n.t("discord.commands.item.fields.grade") => record.grade_label,
          I18n.t("discord.commands.item.fields.class") => record.item_class_label,
          I18n.t("discord.commands.item.fields.buy") => uec(record.sell_price)
        }
      end

      private def equipment_fields(record)
        {
          I18n.t("discord.commands.item.fields.size") => record.size&.to_s,
          I18n.t("discord.commands.item.fields.grade") => record.grade&.to_s,
          I18n.t("discord.commands.item.fields.slot") => record.slot_label,
          I18n.t("discord.commands.item.fields.buy") => uec(record.sell_price)
        }
      end

      # Prices are stored from the shop's side: what a shop sells at is what the
      # reader pays to buy, so the two columns trade places on the way out, as
      # they do on the site. Selling quotes the best-paid shop, not the lowest.
      private def commodity_fields(record)
        {
          I18n.t("discord.commands.item.fields.buy") => uec(record.sell_price),
          I18n.t("discord.commands.item.fields.sell") => uec(record.best_buy_price)
        }
      end

      private def blueprint_fields(record)
        {
          I18n.t("discord.commands.item.fields.craft_time") => craft_time(record.craft_time),
          I18n.t("discord.commands.item.fields.slots") => record.slot_count&.to_s
        }
      end

      # Hours at most: a recipe takes minutes, and Duration's own parts would
      # spell a month and a minute with the same letter.
      private def craft_time(seconds)
        return if seconds.blank?

        hours, rest = seconds.to_i.divmod(3600)
        minutes, seconds = rest.divmod(60)

        {"h" => hours, "m" => minutes, "s" => seconds}
          .filter_map { |unit, amount| "#{amount}#{unit}" if amount.positive? }
          .join(" ").presence || "0s"
      end

      private def images(record)
        %i[store_image icon].filter_map { |name| record.try(name) }
      end
    end
  end
end
