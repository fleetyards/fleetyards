# frozen_string_literal: true

module Discord
  module Commands
    # Where an item can be bought and where it can be sold, as the site's
    # availability list shows it. Blueprints are not offered: no shop sells
    # one.
    class Where < Base
      include ItemLookup

      CATALOGUES = %w[component equipment commodity].freeze
      # Discord rejects the whole message over one embed field past this, and
      # an unanswered interaction stays on "thinking..." for good.
      FIELD_LIMIT = 1024

      def self.autocomplete(option, value)
        return [] unless option == "name"

        ItemLookup.choices(value, within: CATALOGUES)
      end

      def call
        query = option("name").to_s.strip
        return message(content: I18n.t("discord.commands.item.missing_query")) if query.blank?

        prefix, found = resolve_item(query, within: CATALOGUES)
        return found if prefix.nil?

        # Both directions off one query and one shop-link preload rather than
        # one each.
        ItemPrice.with_shop_links(found.item_prices.to_a)
        page = item_page_url(prefix, found.slug)
        fields = [
          field(:buy, found.sold_at, page),
          field(:sell, found.bought_at, page)
        ].compact
        return message(content: I18n.t("discord.commands.where.none", item: item_link(found.name, prefix, found.slug))) if fields.empty?

        message(embeds: [{
          title: found.name,
          url: page,
          color: EMBED_COLOR,
          fields: fields
        }])
      end

      # As many rows as fit, in the order given, and a pointer to the item page
      # for the rest -- whose own length is reserved before the rows are counted.
      private def field(direction, prices, page)
        return nil if prices.empty?

        lines = prices.map { |item_price| line(item_price) }
        shown = []
        lines.each_with_index do |line, index|
          rest = lines.size - index - 1
          reserve = rest.positive? ? more(rest, page).length + 1 : 0
          break if (shown + [line]).join("\n").length + reserve > FIELD_LIMIT

          shown << line
        end

        hidden = lines.size - shown.size
        shown << more(hidden, page) if hidden.positive?

        {name: I18n.t("discord.commands.where.fields.#{direction}"), value: shown.join("\n")}
      end

      private def more(count, page)
        I18n.t("discord.commands.where.more", count: count, url: page)
      end

      # UEX names a terminal "shop - spaceport - city": the shop is what people
      # look for and the rest is where to fly.
      private def line(item_price)
        shop, *place = item_price.location.to_s.split(" - ")

        ["• #{shop_link(item_price, shop)}", Markdown.escape(place.join(" · ")).presence, uec(item_price.price)]
          .compact.join(" · ")
      end

      # The shop's page where one is matched, the source's link where it is a
      # web address -- it is third-party fed, so a `javascript:` one is not --
      # and the bare name otherwise.
      private def shop_link(item_price, name)
        text = Markdown.escape(name)
        return "[#{text}](#{url_for_path("/shops/#{item_price.shop.slug}/")})" if item_price.shop&.slug.present?
        return "[#{text}](#{link_safe(item_price.location_url)})" if item_price.location_url.to_s.match?(%r{\Ahttps?://}i)

        text
      end

      # A space or a bracket ends a markdown link early, and the rest of the
      # address spills into the message as text.
      private def link_safe(url)
        url.gsub(/[\s()<>\[\]]/) { |char| format("%%%02X", char.ord) }
      end
    end
  end
end
