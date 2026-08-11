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
      terminals: uex_fixture("terminals")
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
end
