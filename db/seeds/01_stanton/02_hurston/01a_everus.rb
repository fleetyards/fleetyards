# frozen_string_literal: true

hurston = CelestialObject.find_or_create_by!(name: 'Hurston')

hidden = false

everus = Station.find_or_initialize_by(name: 'Everus Harbor')
everus.update!(
  celestial_object: hurston,
  station_type: :station,
  classification: :trading,
  location: nil,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/everus/everus.jpg').open,
  hidden: hidden,
  refinery: true,
  cargo_hub: true
)

everus.docks.destroy_all
{ small: [3, 4], large: [1, 2] }.each do |ship_size, pads|
  pads.each do |pad|
    everus.docks << Dock.new(
      name: ('%02d' % pad),
      dock_type: :landingpad,
      ship_size: ship_size
    )
  end
end
{ large: [1, 2, 3, 4] }.each do |ship_size, hangars|
  hangars.each do |hangar|
    everus.docks << Dock.new(
      name: ('%02d' % hangar),
      dock_type: :hangar,
      ship_size: ship_size
    )
  end
end

everus.habitations.destroy_all
%w[1 2 3 4 5].each do |level|
  pad = 1
  { container: 10 }.each do |hab_size, count|
    count.times do
      everus.habitations << Habitation.new(
        name: "Level #{'%02d' % level} Hab #{'%02d' % pad}",
        habitation_name: 'EZ Hab',
        habitation_type: hab_size
      )
      pad += 1
    end
  end
end

admin = Shop.find_or_initialize_by(name: 'Admin Office', station: everus)
admin.update!(
  shop_type: :admin,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/everus/admin.jpg').open,
  buying: true,
  selling: true,
  hidden: hidden
)

bulwark_armor = Shop.find_or_initialize_by(name: 'Bulwark Armor', station: everus)
bulwark_armor.update!(
  shop_type: :armor,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/everus/armor.jpg').open,
  selling: true,
  hidden: hidden
)

platinum_bay = Shop.find_or_initialize_by(name: 'Platinum Bay', station: everus)
platinum_bay.update!(
  shop_type: :components,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/everus/platinum_bay.jpg').open,
  selling: true,
  hidden: hidden
)

casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: everus)
casaba.update!(
  shop_type: :clothing,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/everus/casaba.jpg').open,
  selling: true,
  hidden: hidden
)

traveler_rentals = Shop.find_or_initialize_by(name: 'Traveler Rentals', station: everus)
traveler_rentals.update!(
  shop_type: :rental,
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/traveler-rentals.jpg').open,
  rental: true,
  hidden: hidden
)

