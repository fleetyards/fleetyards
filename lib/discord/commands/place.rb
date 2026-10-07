# frozen_string_literal: true

module Discord
  module Commands
    # /location: a place from the starmap -- where it sits, where a ship can set
    # down there, and its shops. Named Place because `Location` inside this
    # namespace would shadow the model.
    class Place < Base
      include CatalogueLookup

      CATALOGUES = %w[location].freeze
      DESCRIPTION_LENGTH = 300
      SIZE_ORDER = ::Dock.ship_sizes.keys.freeze

      def self.autocomplete(option, value)
        return [] unless option == "name"

        CatalogueLookup.choices(value, within: CATALOGUES)
      end

      def call
        query = option("name").to_s.strip
        return message(content: I18n.t("discord.commands.location.missing_query")) if query.blank?

        prefix, found = resolve_entry(query, within: CATALOGUES, strings: "location")
        return found if prefix.nil?

        message(embeds: [embed(found)])
      end

      private def embed(place)
        page = entry_page_url("location", place.slug)

        {
          author: {name: kind_label(place.kind)}.compact_blank.presence,
          title: place.name,
          url: page,
          color: EMBED_COLOR,
          description: [breadcrumb(place), place.description.to_s.truncate(DESCRIPTION_LENGTH).presence].compact.join("\n\n").presence,
          fields: [*facility_fields(place.facilities), shops_field(place, page)].compact,
          thumbnail: thumbnail(place.image)
        }.compact_blank
      end

      private def kind_label(kind)
        I18n.t("discord.commands.location.kinds.#{kind}", default: kind.to_s.humanize) if kind.present?
      end

      # From the system down to the parent, each linked, as the page's own
      # breadcrumb reads.
      private def breadcrumb(place)
        place.ancestors.reverse.map { |ancestor| entry_link(ancestor.name, "location", ancestor.slug) }.join(" › ").presence
      end

      # A free pad is one a pilot lands on without ATC handing it out, so it
      # gets its own line, as on the page.
      private def facility_fields(facilities)
        return [] if facilities.blank?

        pads = Array.wrap(facilities["landing_pads"])
        tubes = facilities["docking_tubes"].to_i

        [
          facility_field(:hangars, facilities["hangars"]),
          facility_field(:free_landing_pads, pads.reject { |pad| pad["atc_assigned"] }),
          facility_field(:landing_pads, pads.select { |pad| pad["atc_assigned"] }),
          facility_field(:vehicle_pads, facilities["vehicle_pads"]),
          ({name: I18n.t("discord.commands.location.fields.docking_tubes"), value: tubes.to_s, inline: true} if tubes.positive?)
        ].compact
      end

      # One count per size, largest first: a station's hangars come as several
      # entries of one size, one per door and pad box.
      private def facility_field(kind, entries)
        counts = Array.wrap(entries).each_with_object(Hash.new(0)) do |entry, sums|
          sums[entry["size"].to_s] += entry["count"].to_i
        end.select { |_, count| count.positive? }
        return nil if counts.empty?

        value = counts.sort_by { |size, _| -SIZE_ORDER.index(size).to_i }
          .map { |size, count| "#{::Dock.human_enum_name(:ship_size, size)} ×#{count}" }
          .join("\n")

        {name: I18n.t("discord.commands.location.fields.#{kind}"), value: value, inline: true}
      end

      private def shops_field(place, page)
        shops = place.shops.order(:name).to_a
        return nil if shops.empty?

        links = shops.map { |shop| shop_link(shop) }
        value = fit_field(links, separator: ", ") { |hidden| I18n.t("discord.commands.location.more_shops", count: hidden, url: page) }

        {name: I18n.t("discord.commands.location.fields.shops"), value: value}
      end
    end
  end
end
