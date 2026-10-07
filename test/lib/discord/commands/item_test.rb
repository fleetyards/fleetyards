# frozen_string_literal: true

require "test_helper"

module Discord
  module Commands
    class ItemTest < ActiveSupport::TestCase
      def call(name)
        ::Discord::Commands::Item.new(options: {"name" => name}).call
      end

      def fields(payload)
        payload[:embeds].first[:fields].to_h { |field| [field[:name], field[:value]] }
      end

      test "answers a commodity with the prices the reader pays and gets" do
        commodity = create(:commodity, name: "Quantainium", commodity_type: "metal")
        create(:item_price, item: commodity, price_type: :sell, price: 88.5)
        create(:item_price, item: commodity, price_type: :buy, price: 1234)

        payload = call("Quantainium")
        embed = payload[:embeds].first

        assert_equal "Quantainium", embed[:title]
        assert_includes embed[:url], "/catalogue/commodities/#{commodity.slug}/"
        assert_equal "88.5 aUEC", fields(payload)[I18n.t("discord.commands.item.fields.buy")]
        assert_equal "1,234 aUEC", fields(payload)[I18n.t("discord.commands.item.fields.sell")]
      end

      test "groups the thousands of a price the way the locale writes them" do
        commodity = create(:commodity, name: "Quantainium")
        create(:item_price, item: commodity, price_type: :sell, price: 1234567.5)

        price = I18n.with_locale(:de) { fields(call("Quantainium"))[I18n.t("discord.commands.item.fields.buy", locale: :de)] }

        assert_equal "1.234.567,5 aUEC", price
      end

      test "quotes the best-paid shop as a commodity's sell price" do
        commodity = create(:commodity, name: "Quantainium")
        create(:item_price, item: commodity, price_type: :buy, price: 80, location: "TDD - Area18")
        create(:item_price, item: commodity, price_type: :buy, price: 110, location: "TDD - Orison")

        assert_equal "110 aUEC", fields(call("Quantainium"))[I18n.t("discord.commands.item.fields.sell")]
      end

      test "carries no flags, since a follow-up cannot set them" do
        create(:commodity, name: "Quantainium")

        assert_nil call("Quantainium")[:flags]
      end

      test "answers a component with its stored facts and its maker" do
        manufacturer = create(:manufacturer, name: "Behring")
        component = create(:component, name: "Mercury Drive", size: 2, grade: 1, manufacturer:)

        payload = call(component.name)
        embed = payload[:embeds].first

        assert_includes embed[:url], "/catalogue/components/#{component.slug}/"
        assert_equal "Behring", embed.dig(:footer, :text)
        assert_equal "2", fields(payload)[I18n.t("discord.commands.item.fields.size")]
        assert_equal "A", fields(payload)[I18n.t("discord.commands.item.fields.grade")]
        assert_includes embed.dig(:author, :name), I18n.t("discord.commands.types.component")
      end

      test "answers equipment" do
        equipment = create(:equipment, name: "P4-AR Rifle")

        embed = call("P4-AR Rifle")[:embeds].first

        assert_includes embed[:url], "/catalogue/equipment/#{equipment.slug}/"
      end

      # A blueprint shares the name of what it crafts, so a bare name keeps
      # meaning the item; the suggestion carries the prefix.
      test "answers a blueprint picked by its token, with what it makes and takes" do
        component = create(:component, name: "Omnisky IX Cannon")
        blueprint = create(:blueprint, name: "Omnisky IX Cannon", craftable: component, craft_time: 150)
        commodity = create(:commodity, name: "Taranite")
        create(:blueprint_cost_option, slot: create(:blueprint_cost_slot, build: blueprint.build), commodity:)

        payload = call("blueprint:Omnisky IX Cannon")
        embed = payload[:embeds].first

        assert_includes embed[:url], "/catalogue/blueprints/#{blueprint.slug}/"
        assert_includes embed[:description], "/catalogue/components/#{component.slug}/"
        assert_includes embed[:description], "[Taranite]"
        assert_equal "2m 30s", fields(payload)[I18n.t("discord.commands.item.fields.craft_time")]
      end

      test "names a material the catalogue does not list without linking it" do
        blueprint = create(:blueprint, name: "Omnisky IX Cannon", craftable: create(:component, name: "Omnisky IX Cannon"))
        commodity = create(:commodity, :without_build, name: "Retired Ore")
        create(:blueprint_cost_option, slot: create(:blueprint_cost_slot, build: blueprint.build), commodity:)

        description = call("blueprint:Omnisky IX Cannon")[:embeds].first[:description]

        assert_includes description, "Retired Ore"
        assert_not_includes description, "/catalogue/commodities/"
      end

      test "a bare name shared with a blueprint answers the item" do
        component = create(:component, name: "Omnisky IX Cannon")
        create(:blueprint, name: "Omnisky IX Cannon", craftable: component)

        assert_includes call("Omnisky IX Cannon")[:embeds].first[:url], "/catalogue/components/"
      end

      test "a partial name that one item matches answers it" do
        create(:commodity, name: "Quantainium")

        assert_equal "Quantainium", call("quantain")[:embeds].first[:title]
      end

      test "several partial matches are listed instead of guessed" do
        create(:commodity, name: "Gold Ore")
        create(:commodity, name: "Gold Bar")

        payload = call("Gold")

        assert_nil payload[:embeds]
        assert_includes payload[:content], "Gold Ore"
        assert_includes payload[:content], "Gold Bar"
      end

      test "says so when nothing matches" do
        assert_equal I18n.t("discord.commands.item.not_found", query: "Nothing Here"), call("Nothing Here")[:content]
      end

      test "does not answer a ship, which has its own command" do
        create(:model, name: "Carrack")

        assert_nil call("ship:Carrack")[:embeds]
      end

      test "ignores what the catalogue no longer lists" do
        create(:commodity, :without_build, name: "Retired Ore")

        assert_nil call("Retired Ore")[:embeds]
      end

      test "suggests items with their type, the token as the value" do
        component = create(:component, name: "Omnisky IX Cannon")
        create(:blueprint, name: "Omnisky IX Cannon", craftable: component)

        choices = ::Discord::Commands::Item.autocomplete("name", "omnisky")

        assert_equal(
          [
            {name: "Omnisky IX Cannon · #{I18n.t("discord.commands.types.component")}", value: "Omnisky IX Cannon"},
            {name: "Omnisky IX Cannon · #{I18n.t("discord.commands.types.blueprint")}", value: "blueprint:Omnisky IX Cannon"}
          ].sort_by { |choice| choice[:value] },
          choices.sort_by { |choice| choice[:value] }
        )
      end

      test "suggests no ships, missions or places" do
        create(:model, name: "Carrack")

        assert_empty ::Discord::Commands::Item.autocomplete("name", "carr")
      end

      test "suggests nothing for another option" do
        create(:commodity, name: "Quantainium")

        assert_empty ::Discord::Commands::Item.autocomplete("other", "quan")
      end

      test "a craft time over an hour reads in hours, not months" do
        create(:blueprint, name: "Long Recipe", craft_time: 3725)

        assert_equal "1h 2m 5s", fields(call("blueprint:Long Recipe"))[I18n.t("discord.commands.item.fields.craft_time")]
      end

      test "a listed name cannot break the link it sits in" do
        create(:commodity, name: "Gold [Refined]")
        create(:commodity, name: "Gold Ore")

        assert_includes call("Gold")[:content], "[Gold \\[Refined\\]]("
      end

      # Discord cannot draw an SVG; a raster icon behind one still gets used.
      test "passes over a vector image for a raster one" do
        component = create(:component, name: "Mercury Drive")
        component.store_image.attach(io: file_fixture("vector.svg").open, filename: "vector.svg", content_type: "image/svg+xml")
        component.icon.attach(io: file_fixture("test.png").open, filename: "test.png", content_type: "image/png")

        assert call("Mercury Drive")[:embeds].first.dig(:thumbnail, :url).present?
      end

      test "leaves out a picture it cannot draw" do
        component = create(:component, name: "Mercury Drive")
        component.icon.attach(io: file_fixture("vector.svg").open, filename: "vector.svg", content_type: "image/svg+xml")

        assert_nil call("Mercury Drive")[:embeds].first[:thumbnail]
      end

      test "leaves out an upload that is not an image" do
        commodity = create(:commodity, name: "Quantainium")
        commodity.store_image.attach(io: StringIO.new("not a picture"), filename: "notes.txt", content_type: "text/plain")

        assert_nil call("Quantainium")[:embeds].first[:thumbnail]
      end

      # The row's column holds whichever source loaded last; the embed links
      # the output the served build names, and its label has to agree.
      test "labels a blueprint by the output its served build names" do
        equipment = create(:equipment, name: "Serac Armor")
        blueprint = create(:blueprint, name: "Serac Armor", craftable: equipment)
        blueprint.update_column(:craftable_type, "Component")

        author = call("blueprint:Serac Armor")[:embeds].first.dig(:author, :name)

        assert_includes author, I18n.t("discord.commands.types.equipment")
      end

      # Two coolers called "Serac" cannot be told apart by a token; the bot
      # offers each, keyed by id, with its size and game key beside the name.
      test "suggests each item of a name a few items share" do
        origin = create(:component, name: "Serac", sc_key: "COOL_ORIG_S04_890J_SCItem", size: 4)
        polaris = create(:component, name: "Serac", sc_key: "COOL_RSI_S04_Polaris_SCItem", size: 4)

        choices = ::Discord::Commands::Item.autocomplete("name", "serac")

        assert_equal ["component~#{origin.id}", "component~#{polaris.id}"].sort, choices.pluck(:value).sort
        assert_includes choices.pluck(:name), "Serac · #{I18n.t("discord.commands.types.component")} · S4 · cool_orig_s04_890j_scitem"
      end

      test "suggests each item of a shared name for a query written with its type" do
        create_list(:component, 2, name: "Serac")

        choices = ::Discord::Commands::Item.autocomplete("name", "component:serac")

        assert_equal 2, choices.size
      end

      test "keeps a shared name that starts with the query over ones that only contain it" do
        ::Discord::Commands::CatalogueVariants::NAMES_PER_CATALOGUE.times do |index|
          create_list(:component, 2, name: "Laser #{index}")
        end
        create_list(:component, 2, name: "Ser Cooler Extended Edition")

        names = ::Discord::Commands::CatalogueVariants.search("ser", within: %w[component]).map(&:name)

        assert_includes names, "Ser Cooler Extended Edition"
      end

      test "suggests no single items of a name many items share" do
        create_list(:component, ::Discord::Commands::CatalogueVariants::MAX_CARRIERS + 1, name: "Internal Tank")

        assert_empty ::Discord::Commands::Item.autocomplete("name", "internal")
      end

      test "a typed name too many items share points at the catalogue narrowed to it" do
        create_list(:component, ::Discord::Commands::CatalogueVariants::MAX_CARRIERS + 1, name: "Internal Tank")
        create(:component, name: "Internal Tank Mk2")

        content = call("Internal Tank")[:content]

        assert_includes content, I18n.t("discord.commands.item.too_common", query: "Internal Tank")
        assert_includes content, "/catalogue/components/?nameCont=Internal+Tank) · #{::Discord::Commands::CatalogueVariants::MAX_CARRIERS + 1}"
      end

      test "a typed name too many items of another catalogue share still links the one item" do
        create_list(:equipment, ::Discord::Commands::CatalogueVariants::MAX_CARRIERS + 1, name: "Internal Tank")
        component = create(:component, name: "Internal Tank")

        content = call("Internal Tank")[:content]

        assert_includes content, "/catalogue/equipment/?nameOrSlugCont=Internal+Tank"
        assert_includes content, "[Internal Tank](https://#{Rails.configuration.app.domain}/catalogue/components/#{component.slug}/)"
      end

      test "a typed name a few items share in each of two catalogues lists them" do
        create_list(:component, 3, name: "Serac")
        create_list(:equipment, 3, name: "Serac")

        content = call("Serac")[:content]

        assert content.start_with?(I18n.t("discord.commands.item.ambiguous", query: "Serac"))
      end

      test "a picked item of a shared name answers that item" do
        create(:component, name: "Serac")
        polaris = create(:component, name: "Serac")

        embed = call("component~#{polaris.id}")[:embeds].first

        assert_includes embed[:url], "/catalogue/components/#{polaris.slug}/"
      end

      test "a typed shared name lists each item that carries it" do
        first = create(:component, name: "Serac")
        second = create(:component, name: "Serac")

        content = call("Serac")[:content]

        assert_includes content, "/catalogue/components/#{first.slug}/"
        assert_includes content, "/catalogue/components/#{second.slug}/"
      end

      test "a picked value naming no listed item says so" do
        value = "component~#{SecureRandom.uuid}"

        assert_equal I18n.t("discord.commands.item.not_found", query: ::Discord::Markdown.escape(value)), call(value)[:content]
      end

      test "sets a typed name in the answer as plain text" do
        content = call("[Free aUEC](https://evil.example)")[:content]

        assert_includes content, "\\[Free aUEC\\]\\(https://evil.example\\)"
      end
    end
  end
end
