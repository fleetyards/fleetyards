# frozen_string_literal: true

module Discord
  module Commands
    # One command for the game-file catalogues, rather than one per catalogue:
    # someone asking for a P4-AR neither knows nor cares which catalogue we file
    # it under. Names resolve through the same resolver as an inline `[*Name*]`
    # in a text, so the bot finds the item the site would for the same words,
    # and a suggestion's value is that token -- a picked one always resolves.
    # A name several items share, which no token can name, is offered per item
    # by ItemVariants.
    class Item < Base
      include ActionView::Helpers::NumberHelper

      CATALOGUES = %w[component equipment commodity blueprint].freeze
      MAX_CANDIDATES = 5
      EMBED_COLOR = 0x2d9cdb
      DESCRIPTION_LENGTH = 300

      # The filter each catalogue page narrows its list by a name with.
      NAME_FILTERS = {
        "component" => "nameCont",
        "equipment" => "nameOrSlugCont",
        "commodity" => "nameCont",
        "blueprint" => "nameCont"
      }.freeze

      PAGES = {
        "component" => "components",
        "equipment" => "equipment",
        "commodity" => "commodities",
        "blueprint" => "blueprints"
      }.freeze

      # One shape for a name the resolver offers and for one item of a shared
      # name, so both rank and list the same way.
      Candidate = Data.define(:prefix, :name, :slug, :value, :detail)

      def self.autocomplete(option, value)
        return [] unless option == "name"

        candidates(value).map do |candidate|
          {name: [candidate.name, type_label(candidate.prefix), candidate.detail].compact.join(" · "), value: candidate.value}
        end
      end

      # Names that start with the query first, then shorter ones, as the
      # resolver ranks its own.
      def self.candidates(query)
        unique = ::Catalogue::TokenResolver.new.search(query, within: CATALOGUES).map do |match|
          Candidate.new(prefix: prefix_for(match), name: match.name, slug: match.slug, value: match.token, detail: nil)
        end
        shared = ItemVariants.search(query, within: CATALOGUES).map do |variant|
          Candidate.new(prefix: variant.prefix, name: variant.name, slug: variant.slug, value: variant.value, detail: variant.detail)
        end

        lowered = ::Catalogue::TokenResolver.parse(query).last.downcase
        (unique + shared).sort_by do |candidate|
          [candidate.name.downcase.start_with?(lowered) ? 0 : 1, candidate.name.length, candidate.name.downcase, candidate.detail.to_s]
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

        variant = ItemVariants.find(query, within: CATALOGUES)
        return message(embeds: [embed(variant.prefix, variant.record)]) if variant

        exact = ::Catalogue::TokenResolver.new.resolve([query], within: CATALOGUES)
        return answer(query, self.class.prefix_for(exact.first), exact.first.slug) if exact.one?

        carriers = ItemVariants.carriers(query, within: CATALOGUES)
        # Per catalogue, as the suggestions count them, so a name they offered
        # item by item is listed the same way when typed out.
        return too_common(query, carriers) if carriers.values.any? { |count| count > ItemVariants::MAX_CARRIERS }

        candidates = self.class.candidates(query)
        return not_found(query) if candidates.empty?
        return answer(query, candidates.first.prefix, candidates.first.slug) if candidates.one?

        candidate_list(query, candidates)
      end

      private def answer(query, prefix, slug)
        record = ::Catalogue::TokenResolver.listed(prefix)
          .find_by(ItemVariants.model(prefix).table_name => {slug:})
        return not_found(query) if record.nil?

        message(embeds: [embed(prefix, record)])
      end

      private def not_found(query)
        message(content: I18n.t("discord.commands.item.not_found", query: Markdown.escape(query)))
      end

      # Too many items to list or offer, so the catalogue pages narrowed to
      # the name stand in for them. A catalogue with only a few of them still
      # lists each, so the one component among six pieces of equipment is not
      # buried with them.
      private def too_common(query, carriers)
        name = ::Catalogue::TokenResolver.parse(query).last
        lines = carriers.flat_map do |prefix, count|
          if count > ItemVariants::MAX_CARRIERS
            url = url_for_path("/catalogue/#{PAGES.fetch(prefix)}/?#{{NAME_FILTERS.fetch(prefix) => name}.to_query}")
            ["• [#{self.class.type_label(prefix)}](#{url}) · #{count}"]
          else
            ItemVariants.named(prefix, name).map do |record|
              "• #{link(record.name, prefix, record.slug)} · #{self.class.type_label(prefix)}"
            end
          end
        end

        message(content: [I18n.t("discord.commands.item.too_common", query: Markdown.escape(query)), *lines].join("\n"))
      end

      private def candidate_list(query, candidates)
        lines = candidates.first(MAX_CANDIDATES).map do |candidate|
          ["• #{link(candidate.name, candidate.prefix, candidate.slug)}", self.class.type_label(candidate.prefix), candidate.detail]
            .compact.join(" · ")
        end

        content = [
          I18n.t("discord.commands.item.ambiguous", query: Markdown.escape(query)),
          lines.join("\n"),
          (I18n.t("discord.commands.item.more") if candidates.size > MAX_CANDIDATES)
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
          listed.include?(commodity.id) ? link(commodity.name, "commodity", commodity.slug) : Markdown.escape(commodity.name)
        end

        [
          (I18n.t("discord.commands.item.makes", item: craftable_link(craftable)) if craftable.present?),
          (I18n.t("discord.commands.item.materials", items: material_links.join(", ")) if materials.any?)
        ].compact.join("\n").presence
      end

      private def craftable_link(craftable)
        prefix = ::Catalogue::TokenResolver::CATALOGUES.key(craftable.class)
        listed = prefix && ::Catalogue::TokenResolver.listed(prefix).exists?(slug: craftable.slug)

        listed ? link(craftable.name, prefix, craftable.slug) : Markdown.escape(craftable.name)
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

        "#{number_with_precision(value, precision: 2, strip_insignificant_zeros: true, delimiter: I18n.t("number.format.delimiter"))} aUEC"
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

      private def link(name, prefix, slug)
        "[#{Markdown.escape(name)}](#{page_url(prefix, slug)})"
      end

      private def page_url(prefix, slug)
        url_for_path("/catalogue/#{PAGES.fetch(prefix)}/#{slug}/")
      end
    end
  end
end
