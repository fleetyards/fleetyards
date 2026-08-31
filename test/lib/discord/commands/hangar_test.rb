# frozen_string_literal: true

require "test_helper"
require "discord/commands/hangar"

module Discord
  module Commands
    class HangarTest < ActiveSupport::TestCase
      setup do
        @user = create(:user, username: "Aendrax", public_hangar: true)
        @carrack = create(:model, name: "Carrack")
      end

      def call(username)
        ::Discord::Commands::Hangar.new(options: {"username" => username}).call
      end

      def add_ship(model, count: 1, public: true, wanted: false)
        count.times { create(:vehicle, user: @user, model: model, public: public, wanted: wanted) }
      end

      test "lists the ships in a public hangar" do
        add_ship(@carrack)

        assert_includes call("Aendrax")[:content], "Carrack"
      end

      test "counts duplicates rather than repeating them" do
        add_ship(@carrack, count: 3)

        assert_includes call("Aendrax")[:content], "3× Carrack"
      end

      test "links the public hangar" do
        add_ship(@carrack)

        assert_includes call("Aendrax")[:content], @user.public_hangar_url
      end

      test "finds a user regardless of case" do
        add_ship(@carrack)

        assert_includes call("aendrax")[:content], "Carrack"
      end

      test "a hangar with only private ships reads as empty" do
        add_ship(@carrack, public: false)

        assert_includes call("Aendrax")[:content], I18n.t("discord.commands.hangar.empty", username: "Aendrax")
      end

      test "a wanted ship is not in the hangar" do
        add_ship(@carrack, wanted: true)

        assert_includes call("Aendrax")[:content], I18n.t("discord.commands.hangar.empty", username: "Aendrax")
      end

      # Mirrors Public::UserPolicy#show?.
      test "a private hangar is not shown" do
        @user.update!(public_hangar: false)
        add_ship(@carrack)

        assert_includes call("Aendrax")[:content], "Aendrax"
        assert_not_includes call("Aendrax")[:content], "Carrack"
      end

      # Otherwise the command becomes a probe for which accounts exist.
      test "a private hangar and an unknown user give the same answer" do
        @user.update!(public_hangar: false)

        assert_equal call("Nobody")[:content].sub("Nobody", "X"), call("Aendrax")[:content].sub("Aendrax", "X")
      end

      # Visibility is not a command's to decide -- RegistryTest and
      # DiscordInteractionsTest cover it where Discord actually reads it.
      test "carries no flags, since a follow-up cannot set them" do
        @user.update!(public_hangar: false)

        assert_nil call("Aendrax")[:flags]
      end

      test "a blank username asks for one" do
        assert_equal I18n.t("discord.commands.hangar.missing_query"), call(" ")[:content]
      end

      test "caps a long hangar and says how many were left out" do
        (::Discord::Commands::Hangar::MAX_SHIPS + 3).times do |i|
          add_ship(create(:model, name: "Ship #{i.to_s.rjust(2, "0")}"))
        end

        content = call("Aendrax")[:content]

        assert_includes content, I18n.t("discord.commands.hangar.more", count: 3)
      end
    end
  end
end
