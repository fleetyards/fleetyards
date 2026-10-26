# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating shopping_cart scenario test data..."

Flipper.add(:shopping_cart) unless Flipper.exist?(:shopping_cart)
Flipper.enable(:shopping_cart)

FactoryBot.create(:user, username: "shopper", password: "password")

system = FactoryBot.create(:location, name: "Stanton System", kind: "system")
everus = FactoryBot.create(:location, name: "Everus Harbor", kind: "station", parent: system, system:)
lorville = FactoryBot.create(:location, name: "Lorville", kind: "city", parent: system, system:)
casaba = Shop.create!(name: "Casaba Outlet", location: everus)
garrity = Shop.create!(name: "Garrity Defense", location: lorville)

jacket = FactoryBot.create(:equipment, name: "Adiva Jacket")
FactoryBot.create(:item_price, item: jacket, price_type: "sell", time_range: nil, price: 210,
  shop: casaba, location: "Casaba Outlet - Everus Harbor")
FactoryBot.create(:item_price, item: jacket, price_type: "sell", time_range: nil, price: 250,
  shop: garrity, location: "Garrity Defense - Lorville")

Rails.logger.info "E2E: Created shopping_cart scenario test data"
