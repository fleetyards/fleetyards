# frozen_string_literal: true

require "test_helper"
require "discord/commands/compare"

module Discord
  module Commands
    class CompareTest < ActiveSupport::TestCase
      setup do
        @first = create(:model, name: "Origin 100i", slug: "orig-100i", cargo: 2, max_crew: 1, min_crew: 1)
        @second = create(:model, name: "Origin 300i", slug: "orig-300i", cargo: 4, max_crew: 1, min_crew: 1)
      end

      def call(first, second)
        ::Discord::Commands::Compare.new(options: {"first" => first, "second" => second}).call
      end

      test "puts both ships' values in one field per stat" do
        fields = call("Origin 100i", "Origin 300i")[:embeds].first[:fields]
        cargo = fields.find { |field| field[:name] == I18n.t("discord.commands.ship.fields.cargo") }

        assert_includes cargo[:value], "Origin 100i: 2 SCU"
        assert_includes cargo[:value], "Origin 300i: 4 SCU"
      end

      test "titles the embed with both names" do
        embed = call("Origin 100i", "Origin 300i")[:embeds].first

        assert_equal I18n.t("discord.commands.compare.title", first: "Origin 100i", second: "Origin 300i"), embed[:title]
      end

      # The compare page reads its selection from the query string, so this link
      # opens the real comparison rather than an empty page.
      test "links the comparison on the site" do
        embed = call("Origin 100i", "Origin 300i")[:embeds].first

        assert_includes embed[:url], "/compare/?"
        assert_includes embed[:url], "models%5B%5D=#{@first.slug}"
        assert_includes embed[:url], "models%5B%5D=#{@second.slug}"
      end

      test "links both ships in the description" do
        embed = call("Origin 100i", "Origin 300i")[:embeds].first

        assert_includes embed[:description], "/ships/#{@first.slug}"
        assert_includes embed[:description], "/ships/#{@second.slug}"
      end

      test "a stat neither ship has is left out" do
        fields = call("Origin 100i", "Origin 300i")[:embeds].first[:fields]

        assert_not_includes fields.map { |field| field[:name] }, I18n.t("discord.commands.ship.fields.price")
      end

      test "a stat only one ship has still shows, with a dash for the other" do
        @second.update!(cargo: nil)

        fields = call("Origin 100i", "Origin 300i")[:embeds].first[:fields]
        cargo = fields.find { |field| field[:name] == I18n.t("discord.commands.ship.fields.cargo") }

        assert_includes cargo[:value], "Origin 100i: 2 SCU"
        assert_includes cargo[:value], "Origin 300i: —"
      end

      test "refuses to compare a ship with itself" do
        payload = call("Origin 100i", "Origin 100i")

        assert_nil payload[:embeds]
        assert_includes payload[:content], "Origin 100i"
      end

      test "a missing second ship asks for both" do
        assert_equal I18n.t("discord.commands.compare.missing_query"), call("Origin 100i", "")[:content]
      end

      test "an unknown first ship is reported before the second is looked up" do
        assert_includes call("Nonexistent", "Origin 300i")[:content], "Nonexistent"
      end

      test "an unknown second ship is reported too" do
        assert_includes call("Origin 100i", "Nonexistent")[:content], "Nonexistent"
      end
    end
  end
end
