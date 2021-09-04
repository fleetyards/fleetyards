# frozen_string_literal: true

crusader = CelestialObject.find_or_create_by!(name: 'Crusader')
crusader.update!(store_image: Rails.root.join('db/seeds/images/stanton/crusader/crusader.jpg').open, hidden: false)

orison = Station.find_or_initialize_by(name: 'Orison')
orison.update!(
  celestial_object: crusader,
  station_type: :landing_zone,
  location: nil,
  classification: :city,
  store_image: Rails.root.join('db/seeds/images/stanton/crusader/orison/main.jpg').open,
  hidden: false
)

orison.docks.destroy_all
{ capital: [13, 14, 18], medium: [3, 4, 6, 7, 8, 21], small: [1, 2, 5], large: [9, 10, 11, 12, 15, 16, 17, 19, 20] }.each do |ship_size, hangars|
  hangars.each do |hangar|
    orison.docks << Dock.new(
      name: ("%02d" % hangar),
      dock_type: :hangar,
      ship_size: ship_size,
    )
  end
end

orison.habitations.destroy_all
17.times do |level|
  pad = 1
  { small_apartment: 3 }.each do |apartment_size, count|
    count.times do
      orison.habitations << Habitation.new(
        name: "Level #{"%02d" % level} Apartment #{"%02d" % pad}",
        habitation_name: 'GREENCIRCLE',
        habitation_type: apartment_size
      )
      pad += 1
    end
  end
end

travler = Shop.find_or_initialize_by(name: 'Traveler Rentals', station: orison)
travler.update!(
  shop_type: :rental,
  location: 'August Dunlow Spaceport',
  rental: true,
  hidden: false
)


tdd = Shop.find_or_initialize_by(name: 'Trade & Development Division', station: orison)
tdd.update!(
  shop_type: :resources,
  location: 'Cloudview Center',
  buying: true,
  selling: true,
  hidden: false
)

general = Shop.find_or_initialize_by(name: 'Orison General', station: orison)
general.update!(
  shop_type: :hospital,
  location: 'Cloudview Center',
  hidden: false
)

ftl = Shop.find_or_initialize_by(name: 'FTL Courier', station: orison)
ftl.update!(
  shop_type: :courier,
  location: 'Cloudview Center - Stratus',
  hidden: false
)

makau = Shop.find_or_initialize_by(name: 'Makau', station: orison)
makau.update!(
  shop_type: :clothing,
  location: 'Cloudview Center - Stratus',
  selling: true,
  hidden: false
)

kelto = Shop.find_or_initialize_by(name: 'Kel-To', station: orison)
kelto.update!(
  shop_type: :superstore,
  location: 'Cloudview Center - Stratus',
  selling: true,
  hidden: false
)

voyarger = Shop.find_or_initialize_by(name: 'Voyager Bar', station: orison)
voyarger.update!(
  shop_type: :bar,
  location: 'Cloudview Center - Stratus',
  hidden: false
)

municipal_services = Shop.find_or_initialize_by(name: 'Orison Municipal Services', station: orison)
municipal_services.update!(
  shop_type: :admin,
  location: 'Providence Industrial Platform',
  buying: true,
  selling: true,
  hidden: false
)

corvalex = Shop.find_or_initialize_by(name: 'Corvalex Shipping', station: orison)
corvalex.update!(
  shop_type: :cargo,
  location: 'Providence Industrial Platform',
  selling: true,
  hidden: false
)

tammany_and_sons = Shop.find_or_initialize_by(name: 'Tammany and Sons', station: orison)
tammany_and_sons.update!(
  shop_type: :superstore,
  location: 'Providence Industrial Platform',
  selling: true,
  hidden: true
)

crows = Shop.find_or_initialize_by(name: 'Cousin Crows', station: orison)
crows.update!(
  shop_type: :ship_customizations,
  location: 'Providence Industrial Platform',
  selling: true,
  hidden: true
)

crusader_discovery = Shop.find_or_initialize_by(name: 'Crusader Discovery Center', station: orison)
crusader_discovery.update!(
  shop_type: :souvenirs,
  location: 'Providence Industrial Platform',
  selling: true,
  hidden: false
)
