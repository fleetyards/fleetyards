# frozen_string_literal: true

require "test_helper"

module Discord
  module Commands
    class PlaceTest < ActiveSupport::TestCase
      setup do
        @stanton = create(:location, name: "Stanton", kind: "system", sc_key: "Stanton")
        @hurston = create(:location, name: "Hurston", kind: "planet", parent: @stanton, system: @stanton)
        @harbor = create(:location, name: "Everus Harbor", kind: "station", parent: @hurston, system: @stanton)
      end

      def call(name)
        ::Discord::Commands::Place.new(options: {"name" => name}).call
      end

      def fields(payload)
        payload[:embeds].first[:fields].to_h { |field| [field[:name], field[:value]] }
      end

      def label(key)
        I18n.t("discord.commands.location.fields.#{key}")
      end

      def shop(name, sells: (@ore ||= create(:commodity, name: "Agricium")))
        Shop.create!(name:, location: @harbor).tap do |shop|
          create(:item_price, shop:, item: sells) if sells
        end
      end

      test "answers a place with its kind, system and page" do
        embed = call("location:Everus Harbor")[:embeds].first

        assert_equal "Everus Harbor", embed[:title]
        assert_includes embed[:url], "/locations/#{@harbor.slug}/"
        assert_equal I18n.t("discord.commands.location.kinds.station"), embed.dig(:author, :name)
      end

      test "leads the description with where the place sits, each step linked" do
        description = call("location:Everus Harbor")[:embeds].first[:description]

        assert_match %r{\A\[Stanton\]\(.*/locations/#{@stanton.slug}/\) › \[Hurston\]\(.*/locations/#{@hurston.slug}/\)}, description
      end

      # A typed name needs no prefix: the command only looks for places.
      test "resolves a place typed without its prefix" do
        assert_equal "Everus Harbor", call("everus")[:embeds].first[:title]
      end

      test "counts hangars and pads per size, largest first, with free pads apart" do
        facilities = {
          "hangars" => [{"size" => "medium", "count" => 2}, {"size" => "large", "count" => 4}, {"size" => "medium", "count" => 1}],
          "landing_pads" => [{"size" => "small", "count" => 3, "atc_assigned" => false}, {"size" => "large", "count" => 1, "atc_assigned" => true}],
          "vehicle_pads" => [],
          "docking_tubes" => 4
        }
        @harbor.update!(facilities:)
        @harbor.builds.update_all(facilities:)

        found = fields(call("location:Everus Harbor"))

        assert_equal "#{::Dock.human_enum_name(:ship_size, "large")} ×4\n#{::Dock.human_enum_name(:ship_size, "medium")} ×3", found[label(:hangars)]
        assert_equal "#{::Dock.human_enum_name(:ship_size, "small")} ×3", found[label(:free_landing_pads)]
        assert_equal "#{::Dock.human_enum_name(:ship_size, "large")} ×1", found[label(:landing_pads)]
        assert_equal "4", found[label(:docking_tubes)]
        assert_not found.key?(label(:vehicle_pads))
      end

      test "lists its shops, linked" do
        shop = shop("Casaba Outlet")

        assert_includes fields(call("location:Everus Harbor"))[label(:shops)], "[Casaba Outlet](https://#{Rails.configuration.app.domain}/shops/#{shop.slug}/)"
      end

      test "keeps a long shop list within a field and points to the place page" do
        40.times { |index| shop("A Rather Long Shop Name Number #{index}") }

        value = fields(call("location:Everus Harbor"))[label(:shops)]

        assert_operator value.length, :<=, 1024
        assert_includes value, "/locations/#{@harbor.slug}/"
      end

      # The place page leaves a shop out until it sells something listed, and
      # the "more on the place page" count has to agree with it.
      test "leaves out a shop selling nothing the catalogue lists" do
        shop("Casaba Outlet")
        shop("Empty Counter", sells: nil)

        value = fields(call("location:Everus Harbor"))[label(:shops)]

        assert_includes value, "Casaba Outlet"
        assert_not_includes value, "Empty Counter"
      end

      test "leaves out a pad size the dock sizes do not know" do
        facilities = {"landing_pads" => [{"size" => "small", "count" => 2, "atc_assigned" => true}, {"size" => "colossal", "count" => 1, "atc_assigned" => true}]}
        @harbor.update!(facilities:)
        @harbor.builds.update_all(facilities:)

        assert_equal "#{::Dock.human_enum_name(:ship_size, "small")} ×2", fields(call("location:Everus Harbor"))[label(:landing_pads)]
      end

      test "a place without facilities or shops answers without those fields" do
        assert_empty call("location:Everus Harbor")[:embeds].first.fetch(:fields, [])
      end

      test "says so when no place matches" do
        assert_equal I18n.t("discord.commands.location.not_found", query: "Nowhere"), call("Nowhere")[:content]
      end

      # Both Outpost 54s sit on Aberdeen, so the parent alone cannot tell them
      # apart; the game key follows it.
      test "suggests each place of a shared name, told apart by parent and key" do
        aberdeen = create(:location, name: "Aberdeen", kind: "moon", parent: @hurston, system: @stanton)
        reyes = create(:location, name: "Outpost 54", kind: "outpost", parent: aberdeen, system: @stanton, sc_key: "Outpost54_Reyes")
        create(:location, name: "Outpost 54", kind: "outpost", parent: aberdeen, system: @stanton, sc_key: "Outpost54_Sloane")

        choices = ::Discord::Commands::Place.autocomplete("name", "outpost 54")

        assert_includes choices, {name: "Outpost 54 · Aberdeen · outpost54_reyes", value: "location~#{reyes.id}"}
        assert_equal 2, choices.size
      end

      test "ranks a place starting with a prefixed query first" do
        create(:location, name: "Lorville", kind: "city", parent: @hurston, system: @stanton)
        create(:location, name: "Old Lor", kind: "outpost", parent: @hurston, system: @stanton)

        assert_equal "location:Lorville", ::Discord::Commands::Place.autocomplete("name", "location:lor").first[:value]
      end

      # Discord cuts a choice at 100 characters; the key that tells two places
      # apart has to survive it, so the name gives way.
      test "shortens a long shared name rather than the key after it" do
        long = "A Very Long Outpost Name That Goes On And On Well Past What Fits Into A Choice"
        aberdeen = create(:location, name: "Aberdeen", kind: "moon", parent: @hurston, system: @stanton)
        create(:location, name: long, kind: "outpost", parent: aberdeen, system: @stanton, sc_key: "Outpost_Long_Reyes")
        create(:location, name: long, kind: "outpost", parent: aberdeen, system: @stanton, sc_key: "Outpost_Long_Sloane")

        names = ::Discord::Commands::Place.autocomplete("name", "very long outpost").pluck(:name)

        assert_equal 2, names.size
        names.each { |name| assert_operator name.length, :<=, 100 }
        assert names.any? { |name| name.end_with?("Aberdeen · outpost_long_reyes") }
        assert names.any? { |name| name.end_with?("Aberdeen · outpost_long_sloane") }
      end

      test "a shared name typed with its prefix lists each place, escaped and without the type" do
        aberdeen = create(:location, name: "Aber_deen", kind: "moon", parent: @hurston, system: @stanton)
        create(:location, name: "Outpost 54", kind: "outpost", parent: aberdeen, system: @stanton, sc_key: "Outpost54_Reyes")
        create(:location, name: "Outpost 54", kind: "outpost", parent: aberdeen, system: @stanton, sc_key: "Outpost54_Sloane")

        content = call("location:Outpost 54")[:content]

        assert_includes content, I18n.t("discord.commands.location.ambiguous", query: "location:Outpost 54")
        assert_includes content, "Aber\\_deen · outpost54\\_reyes"
        assert_includes content, "Aber\\_deen · outpost54\\_sloane"
        assert_no_match(/ · #{Regexp.escape(I18n.t("discord.commands.types.location"))} · /, content)
      end

      test "suggests no catalogue items" do
        create(:commodity, name: "Everus Ore")

        assert_equal ["location:Everus Harbor"], ::Discord::Commands::Place.autocomplete("name", "everus").pluck(:value)
      end

      # A bare name resolves only in the item catalogues; a typed place name
      # must still open the place another place's name contains.
      test "a full name typed by hand opens that place, not a list" do
        create(:location, name: "Everus Harbor Spaceport", kind: "spaceport", parent: @harbor, system: @stanton)

        assert_equal "Everus Harbor", call("Everus Harbor")[:embeds].first[:title]
      end
    end
  end
end
