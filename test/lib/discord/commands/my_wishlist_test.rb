# frozen_string_literal: true

require "test_helper"
require "discord/commands/my_wishlist"

module Discord
  module Commands
    class MyWishlistTest < ActiveSupport::TestCase
      DISCORD_UID = "515151515151"

      setup do
        @user = create(:user, username: "Aendrax", public_wishlist: false)
        create(:omniauth_connection, user: @user, provider: :discord, uid: DISCORD_UID)
        @carrack = create(:model, name: "Carrack")
      end

      def call(uid: DISCORD_UID)
        ::Discord::Commands::MyWishlist.new(discord_user_id: uid).call
      end

      def add_ship(model, count: 1, wanted: true, public: false)
        count.times { create(:vehicle, user: @user, model: model, wanted: wanted, public: public) }
      end

      test "lists what is on your wishlist" do
        add_ship(@carrack)

        assert_includes call[:content], "Carrack"
      end

      test "a private wishlist is still shown to its owner" do
        add_ship(@carrack)

        refute @user.reload.public_wishlist
        assert_includes call[:content], "Carrack"
      end

      test "counts duplicates rather than repeating them" do
        add_ship(@carrack, count: 2)

        assert_includes call[:content], "2× Carrack"
      end

      # The scope is the only thing separating this from /myhangar, so it is the
      # thing worth pinning.
      test "a ship you already own is not on the wishlist" do
        add_ship(@carrack, wanted: false)

        assert_includes call[:content], I18n.t("discord.commands.my_wishlist.empty", url: "https://#{Rails.configuration.app.domain}/hangar/wishlist/")
      end

      test "links your own wishlist page" do
        add_ship(@carrack)

        assert_includes call[:content], "/hangar/wishlist/"
      end

      test "an unlinked Discord account is told where to link it" do
        assert_equal(
          I18n.t("discord.commands.account_not_linked", url: "https://#{Rails.configuration.app.domain}/settings/connections"),
          call(uid: "not-linked-at-all")[:content]
        )
      end

      test "carries no flags, since a follow-up cannot set them" do
        assert_nil call[:flags]
      end

      test "caps a long wishlist and says how many were left out" do
        (::Discord::Commands::MyWishlist::MAX_SHIPS + 2).times do |i|
          add_ship(create(:model, name: "Ship #{i.to_s.rjust(2, "0")}"))
        end

        assert_includes call[:content], I18n.t("discord.commands.my_wishlist.more", count: 2)
      end
    end
  end
end
