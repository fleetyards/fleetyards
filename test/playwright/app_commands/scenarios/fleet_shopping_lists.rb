# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating fleet_shopping_lists scenario test data..."

quartermaster = FactoryBot.create(:user, username: "quartermaster", password: "password")
recruit = FactoryBot.create(:user, username: "recruit", password: "password")

fleet = FactoryBot.create(:fleet, name: "Merc Guild", fid: "MERCGUILD", admins: [quartermaster], members: [recruit])

system = FactoryBot.create(:location, name: "Stanton System", kind: "system")
everus = FactoryBot.create(:location, name: "Everus Harbor", kind: "station", parent: system, system:)
casaba = Shop.create!(name: "Casaba Outlet", location: everus)

jacket = FactoryBot.create(:equipment, name: "Adiva Jacket")
FactoryBot.create(:item_price, item: jacket, price_type: "sell", time_range: nil, price: 210,
  shop: casaba, location: "Casaba Outlet - Everus Harbor")

uniform = FactoryBot.create(:cart, user: quartermaster, name: "Uniform")
FactoryBot.create(:cart_item, cart: uniform, item: jacket, quantity: 2)

kit = FactoryBot.create(:fleet_shopping_list, fleet:, name: "Standard kit")
FactoryBot.create(:fleet_shopping_list_item, fleet_shopping_list: kit, item: jacket, quantity: 1)

Rails.logger.info "E2E: Created fleet_shopping_lists scenario test data"
