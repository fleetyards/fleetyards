# frozen_string_literal: true

module Discord
  module Commands
    # Where an item can be bought and where it can be sold, as the site's
    # availability list shows it. Blueprints are not offered: no shop sells
    # one.
    class Where < Base
      include CatalogueLookup

      CATALOGUES = %w[component equipment commodity].freeze

      def call
        prefix, found = lookup_entry
        return found if prefix.nil?

        # Both directions off one query and one shop-link preload rather than
        # one each.
        ItemPrice.with_shop_links(found.item_prices.to_a)
        page = entry_page_url(prefix, found.slug)
        fields = [
          field(:buy, found.sold_at, page),
          field(:sell, found.bought_at, page)
        ].compact
        return message(content: I18n.t("discord.commands.where.none", item: entry_link(found.name, prefix, found.slug))) if fields.empty?

        message(embeds: [{
          title: found.name,
          url: page,
          color: EMBED_COLOR,
          fields: fields
        }])
      end

      # As many rows as fit, in the order given, and a pointer to the item page
      # for the rest.
      private def field(direction, prices, page)
        return nil if prices.empty?

        # Two terminals can share a name and a price, and a row says nothing
        # that tells them apart.
        lines = prices.map { |item_price| line(item_price) }.uniq
        value = fit_field(lines) { |hidden| more(hidden, page) }
        {name: I18n.t("discord.commands.where.fields.#{direction}"), value: value}
      end

      private def more(count, page)
        I18n.t("discord.commands.where.more", count: count, url: page)
      end

      # UEX names a terminal "shop - spaceport - city": the shop is what people
      # look for and the rest is where to fly.
      private def line(item_price)
        shop, *place = item_price.location.to_s.split(" - ")

        parts = [shop_link(item_price, shop), Markdown.escape(place.join(" · ")).presence, uec(item_price.price)]
        "• #{parts.compact.join(" · ")}"
      end

      # The shop's page where one is matched, the source's link where it is a
      # web address -- it is third-party fed, so a `javascript:` one is not --
      # and the bare name otherwise. A matched shop names itself; an empty name
      # would make the link invisible.
      private def shop_link(item_price, name)
        text = Markdown.escape(item_price.shop&.name.presence || name.to_s.strip)
        return nil if text.blank?

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
