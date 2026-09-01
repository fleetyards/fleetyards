# frozen_string_literal: true

require "test_helper"
require "discord/commands/my_hangar"

module Discord
  module Commands
    class MyHangarTest < ActiveSupport::TestCase
      DISCORD_UID = "424242424242"

      setup do
        @user = create(:user, username: "Aendrax", public_hangar: false)
        create(:omniauth_connection, user: @user, provider: :discord, uid: DISCORD_UID)
        @carrack = create(:model, name: "Carrack")
      end

      def call(uid: DISCORD_UID)
        ::Discord::Commands::MyHangar.new(discord_user_id: uid).call
      end

      def add_ship(model, count: 1, public: true, wanted: false, hidden: false)
        count.times { create(:vehicle, user: @user, model: model, public: public, wanted: wanted, hidden: hidden) }
      end

      test "lists your own ships" do
        add_ship(@carrack)

        assert_includes call[:content], "Carrack"
      end

      # The whole reason this is not `/hangar` with the username filled in: the
      # owner's own answer must not be filtered by the flags that exist to keep
      # strangers out.
      test "a private hangar is still shown to its owner" do
        add_ship(@carrack, public: false)

        assert_includes call[:content], "Carrack"
      end

      test "a private ship in a public hangar is still shown to its owner" do
        @user.update!(public_hangar: true)
        add_ship(@carrack, public: false)

        assert_includes call[:content], "Carrack"
      end

      test "counts duplicates rather than repeating them" do
        add_ship(@carrack, count: 3)

        assert_includes call[:content], "3× Carrack"
      end

      # `hidden` is written only by the loaner setup, to mark a duplicate loaner
      # row. Counting those would report ships the owner does not have twice.
      test "a hidden duplicate loaner row is not counted" do
        add_ship(@carrack)
        add_ship(@carrack, hidden: true)

        assert_includes call[:content], "Carrack"
        assert_not_includes call[:content], "2× Carrack"
      end

      test "a wishlist entry is not in the hangar" do
        add_ship(@carrack, wanted: true)

        assert_includes call[:content], I18n.t("discord.commands.my_hangar.empty", url: "https://#{Rails.configuration.app.domain}/hangar")
      end

      test "links your own hangar rather than the public one" do
        add_ship(@carrack)

        assert_includes call[:content], "/hangar"
        assert_not_includes call[:content], @user.public_hangar_url
      end

      # The most frequently seen answer of the command, and the only one that is
      # also a conversion path.
      test "an unlinked Discord account is told where to link it" do
        assert_equal(
          I18n.t("discord.commands.account_not_linked", url: "https://#{Rails.configuration.app.domain}/settings/connections"),
          call(uid: "not-linked-at-all")[:content]
        )
      end

      test "a linked account belonging to another provider does not resolve" do
        ::OmniauthConnection.find_by(uid: DISCORD_UID).update!(provider: :twitch)

        assert_includes call[:content], I18n.t("discord.commands.account_not_linked", url: "https://#{Rails.configuration.app.domain}/settings/connections")
      end

      # Visibility is fixed at the acknowledgement; RegistryTest and
      # DiscordInteractionsTest cover it where Discord actually reads it.
      test "carries no flags, since a follow-up cannot set them" do
        assert_nil call[:flags]
      end

      test "caps a long hangar and says how many were left out" do
        (::Discord::Commands::MyHangar::MAX_SHIPS + 3).times do |i|
          add_ship(create(:model, name: "Ship #{i.to_s.rjust(2, "0")}"))
        end

        assert_includes call[:content], I18n.t("discord.commands.my_hangar.more", count: 3)
      end
    end
  end
end
