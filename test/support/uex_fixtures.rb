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
      commodities: uex_fixture("commodities")
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
end
