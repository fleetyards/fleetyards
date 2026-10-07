# frozen_string_literal: true

require "test_helper"

module Discord
  module Commands
    class WhereTest < ActiveSupport::TestCase
      setup do
        @commodity = create(:commodity, name: "Quantainium")
      end

      def call(name)
        ::Discord::Commands::Where.new(options: {"name" => name}).call
      end

      def field(payload, direction)
        payload[:embeds].first[:fields].find { |field| field[:name] == I18n.t("discord.commands.where.fields.#{direction}") }&.dig(:value)
      end

      def price(type, amount, location, **attributes)
        create(:item_price, item: @commodity, price_type: type, price: amount, location: location, location_url: nil, **attributes)
      end

      test "lists where to buy, cheapest first, with the shop and the place apart" do
        price(:sell, 120, "Admin - Port Tressler - Microtech")
        price(:sell, 95, "Admin - Everus Harbor - Hurston")

        lines = field(call("Quantainium"), :buy).split("\n")

        assert_equal "• Admin · Everus Harbor · Hurston · 95 aUEC", lines.first
        assert_equal "• Admin · Port Tressler · Microtech · 120 aUEC", lines.second
      end

      test "lists where to sell, best paid first" do
        price(:buy, 80, "TDD - Area18 - ArcCorp")
        price(:buy, 110, "TDD - Orison - Crusader")

        lines = field(call("Quantainium"), :sell).split("\n")

        assert_includes lines.first, "110 aUEC"
        assert_includes lines.second, "80 aUEC"
      end

      test "links the shop's page where a shop is matched" do
        shop = Shop.create!(name: "Admin", location: create(:location, name: "Everus Harbor"))
        price(:sell, 95, "Admin - Everus Harbor - Hurston", shop: shop)

        assert_includes field(call("Quantainium"), :buy), "[Admin](https://#{Rails.configuration.app.domain}/shops/#{shop.slug}/)"
      end

      test "does not link a location url that is not a web address" do
        item_price = price(:sell, 95, "Admin - Everus Harbor - Hurston")
        item_price.update_column(:location_url, "javascript:alert(1)")

        assert_not_includes field(call("Quantainium"), :buy), "javascript:"
      end

      test "leaves out a direction nobody trades in" do
        price(:sell, 95, "Admin - Everus Harbor - Hurston")

        assert_nil field(call("Quantainium"), :sell)
      end

      test "says so when nobody trades the item" do
        assert_includes call("Quantainium")[:content], "Quantainium"
        assert_nil call("Quantainium")[:embeds]
      end

      # Discord rejects a message with one field over 1024 characters, which
      # leaves the interaction on "thinking..." for good.
      test "keeps a long list within a field and points to the item page" do
        40.times { |index| price(:sell, 100 + index, "Admin Office Number #{index} - Some Long Station Name - Some Planet") }

        value = field(call("Quantainium"), :buy)

        assert_operator value.length, :<=, 1024
        assert_includes value.lines.last, "/catalogue/commodities/#{@commodity.slug}/"
      end

      test "offers no blueprints, which no shop sells" do
        create(:blueprint, name: "Quantainium Drill")

        assert_empty ::Discord::Commands::Where.autocomplete("name", "quantainium drill")
      end

      test "suggests what /item suggests for the catalogues it covers" do
        assert_equal [{name: "Quantainium · #{I18n.t("discord.commands.item.types.commodity")}", value: "Quantainium"}],
          ::Discord::Commands::Where.autocomplete("name", "quanta")
      end

      test "a place from the price source cannot format the message" do
        price(:sell, 95, "Admin - Port_Tressler - Micro*tech")

        assert_includes field(call("Quantainium"), :buy), "Port\\_Tressler · Micro\\*tech"
      end

      test "a source link with a space stays one link" do
        price(:sell, 95, "Admin - Everus Harbor", location_url: "https://uex.space/terminal/Admin Office (1)")

        assert_includes field(call("Quantainium"), :buy), "[Admin](https://uex.space/terminal/Admin%20Office%20%281%29)"
      end
    end
  end
end
