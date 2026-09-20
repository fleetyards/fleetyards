# frozen_string_literal: true

module UexFixtures
  def uex_fixture(name)
    JSON.parse(File.read(Rails.root.join("test/fixtures/uex/#{name}.json")))["data"]
  end

  def uex_client_stub(overrides = {})
    data = {
      vehicles: uex_fixture("vehicles"),
      vehicle_purchase_prices: uex_fixture("vehicles_purchases_prices_all"),
      vehicle_rental_prices: uex_fixture("vehicles_rentals_prices_all"),
      terminals: uex_fixture("terminals"),
      commodities: uex_fixture("commodities"),
      commodity_prices: uex_fixture("commodities_prices_all"),
      item_prices: uex_fixture("items_prices_all")
    }.merge(overrides)

    client = mock("Uex::Client")
    data.each { |method, rows| client.stubs(method).returns(rows) }
    client
  end

  # The four models the fixture vehicles are expected to resolve to, one per
  # matching layer.
  def create_uex_fixture_models
    {
      slug_match: create(:model, name: "100i", manufacturer: create(:manufacturer, code: "ORIG")),
      name_match: create(:model, name: "Avenger Titan", manufacturer: create(:manufacturer, code: "AEGS")),
      name_full_match: create(:model, name: "Constellation Andromeda", manufacturer: create(:manufacturer, code: "RSI")),
      mapping_match: create(:model, name: "C2 Hercules", manufacturer: create(:manufacturer, code: "CRUS"))
    }
  end

  # The commodities the fixture UEX rows are expected to resolve to: two by
  # name, one through MAPPINGS, and one UEX offers a near-neighbour for
  # ("Organics") that must not be taken as a match.
  def create_uex_fixture_commodities
    {
      name_match: create(:commodity, name: "Gold", sc_key: "items_commodities_gold"),
      punctuated_match: create(:commodity, name: "Agricium (Ore)", sc_key: "items_commodities_agricium_ore"),
      mapping_match: create(:commodity, name: "Lastaprene", sc_key: "items_commodities_lastaprene"),
      near_neighbour: create(:commodity, name: "Organs", sc_key: "items_commodities_organs")
    }
  end

  # The price feed joins on uex_id rather than on name, so the price tests need
  # commodities already carrying the ids the mapper would have written.
  # The components the fixture item prices are expected to resolve to, one per
  # matching layer, plus the two that must not be priced.
  #
  # `sc_ref` is the game file's own id and is what UEX carries as `item_uuid`,
  # so the first of these matches on that rather than on its name -- which is
  # deliberately not the name UEX uses, to prove the uuid is what did it.
  def create_uex_priced_components
    {
      ref_match: create(:component, name: "Omnisky III", sc_key: "behr_lasercannon_s3",
        sc_ref: "aaaaaaaa-0000-0000-0000-000000000001"),
      name_match: create(:component, name: "Sunrise Cooler", sc_key: "jspc_cooler_s1", sc_ref: nil),
      mapping_match: create(:component, name: "RN-7s", sc_key: "fuel_nozzle_misc_nozzlestandard", sc_ref: nil),
      # Three of a name, so nothing says which one the shop stocks.
      ambiguous: [
        create(:component, name: "VariPuck S3 Gimbal Mount", sc_key: "mount_gimbal_s3", sc_ref: nil),
        create(:component, name: "VariPuck S3 Gimbal Mount", sc_key: "mount_gimbal_s3_polaris", sc_ref: nil),
        create(:component, name: "VariPuck S3 Gimbal Mount", sc_key: "mount_gimbal_s3_perseus", sc_ref: nil)
      ],
      # Shares the "RN-7s" name with the mapped one and must lose to it.
      mapping_loser: create(:component, name: "RN-7s", sc_key: "dockingtube_refuelnozzle_armonly_starfarer", sc_ref: nil),
      free: create(:component, name: "Free Sample Cooler", sc_key: "jspc_cooler_s0", sc_ref: nil)
    }
  end

  def create_uex_priced_commodities
    {
      gold: create(:commodity, name: "Gold", sc_key: "items_commodities_gold", uex_id: 33, uex_code: "GOLD"),
      agricium_ore: create(:commodity, name: "Agricium (Ore)", sc_key: "items_commodities_agricium_ore", uex_id: 24, uex_code: "AGRIORE"),
      unmapped: create(:commodity, name: "Vent Slug", sc_key: "items_commodities_ventslug", uex_id: nil)
    }
  end
end
