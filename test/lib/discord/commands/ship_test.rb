# frozen_string_literal: true

require "test_helper"
require "discord/commands/ship"

module Discord
  module Commands
    class ShipTest < ActiveSupport::TestCase
      setup do
        @manufacturer = create(:manufacturer, name: "Anvil Aerospace")
        @model = create(:model,
          name: "Carrack",
          slug: "carrack",
          manufacturer: @manufacturer,
          classification: "explorer",
          price: 4_500_000,
          pledge_price: 600)
      end

      def call(name)
        ::Discord::Commands::Ship.new(options: {"name" => name}).call
      end

      test "answers a single match with an embed" do
        payload = call("Carrack")
        embed = payload[:embeds].first

        assert_equal "Carrack", embed[:title]
        assert_includes embed[:url], "/ships/#{@model.slug}"
        assert_equal "Anvil Aerospace", embed.dig(:footer, :text)
      end

      test "a single match is posted publicly rather than only to the caller" do
        payload = call("Carrack")

        assert_nil payload[:flags]
      end

      test "the embed carries the labels the site uses" do
        fields = call("Carrack")[:embeds].first[:fields].to_h { |field| [field[:name], field[:value]] }

        assert_equal "Explorer", fields[I18n.t("discord.commands.ship.fields.classification")]
        assert_equal "3–4", fields[I18n.t("discord.commands.ship.fields.crew")]
        assert_equal @model.pledge_price_label, fields[I18n.t("discord.commands.ship.fields.pledge_price")]
        assert_equal @model.price_label, fields[I18n.t("discord.commands.ship.fields.price")]
      end

      test "an exact name wins over a longer partial match" do
        create(:model, name: "Carrack Expedition", slug: "carrack-expedition", manufacturer: @manufacturer)

        payload = call("Carrack")

        assert_equal "Carrack", payload[:embeds].first[:title]
      end

      test "several partial matches are listed instead of guessed" do
        create(:model, name: "Hornet F7C", slug: "hornet-f7c", manufacturer: @manufacturer)
        create(:model, name: "Hornet F7A", slug: "hornet-f7a", manufacturer: @manufacturer)

        payload = call("Hornet")

        assert_nil payload[:embeds]
        assert_includes payload[:content], "Hornet F7C"
        assert_includes payload[:content], "Hornet F7A"
      end

      test "a listing is only shown to the caller" do
        create(:model, name: "Hornet F7C", slug: "hornet-f7c", manufacturer: @manufacturer)
        create(:model, name: "Hornet F7A", slug: "hornet-f7a", manufacturer: @manufacturer)

        assert_equal ::Discord::Commands::Base::EPHEMERAL, call("Hornet")[:flags]
      end

      test "answers a miss with a message rather than an empty embed" do
        payload = call("Nonexistent Ship")

        assert_nil payload[:embeds]
        assert_includes payload[:content], "Nonexistent Ship"
      end

      test "a blank name asks for one" do
        payload = call("  ")

        assert_equal I18n.t("discord.commands.ship.missing_query"), payload[:content]
      end

      # The public catalogue scope, so the bot cannot answer with models the
      # website itself refuses to show.
      test "does not answer with a hidden model" do
        create(:model, name: "Secret Prototype", slug: "secret-prototype", hidden: true)

        payload = call("Secret Prototype")

        assert_nil payload[:embeds]
      end

      test "does not answer with an inactive model" do
        create(:model, name: "Retired Hull", slug: "retired-hull", active: false)

        payload = call("Retired Hull")

        assert_nil payload[:embeds]
      end

      test "matches on the manufacturer slug the way the ship list does" do
        payload = call(@manufacturer.slug)

        assert payload[:embeds].present? || payload[:content].present?
      end

      test "answers in the locale the interaction carried" do
        german = I18n.with_locale(:de) { call("Nonexistent Ship") }

        assert_includes german[:content], "Kein Schiff"
      end
    end
  end
end
