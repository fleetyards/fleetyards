# frozen_string_literal: true

arccorp = CelestialObject.find_or_create_by!(name: 'ArcCorp')
arccorp.update!(
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/arccorp.png').open,
  hidden: false
)

area18 = Station.find_or_initialize_by(name: 'Area 18')
area18.update!(
  celestial_object: arccorp,
  station_type: :spaceport,
  location: 'Area 18',
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/area18.jpg').open,
  hidden: false
)

area18.docks.destroy_all
{ small: [1, 6, 10], medium: [2, 7, 9], large: [4, 5], capital: [3, 8] }.each do |ship_size, hangars|
  hangars.each do |hangar|
    area18.docks << Dock.new(
      name: ("%02d" % hangar),
      dock_type: :hangar,
      ship_size: ship_size,
    )
  end
end

area18.habitations.destroy_all
%w[1 2 3 4 5 6].each do |level|
  pad = 1
  { small_apartment: 10 }.each do |apartment_size, count|
    count.times do
      area18.habitations << Habitation.new(
        name: "Level #{"%02d" % level} Apartment #{"%02d" % pad}",
        habitation_name: 'Adira Falls Apartments',
        habitation_type: apartment_size
      )
      pad += 1
    end
  end
end

astro = Shop.find_or_initialize_by(name: 'Astro Armada', station: area18)
astro.update!(
  shop_type: :ships,
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/area18/astro.png').open,
  selling: true,
  hidden: false
)

dumpers_depot = Shop.find_or_initialize_by(name: "Dumper's Depot", station: area18)
dumpers_depot.update!(
  shop_type: :components,
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/area18/dumpers_depot.jpg').open,
  selling: true,
  hidden: false
)

casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: area18)
casaba.update!(
  shop_type: :clothing,
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/area18/casaba.jpg').open,
  selling: true,
  hidden: false
)

cubby_blast = Shop.find_or_initialize_by(name: 'Cubby Blast', station: area18)
cubby_blast.update!(
  shop_type: :armor_and_weapons,
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/area18/weapons.jpg').open,
  selling: true,
  hidden: false
)

gloc = Shop.find_or_initialize_by(name: 'G-LOC Bar', station: area18)
gloc.update!(
  shop_type: :bar,
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/area18/g-loc.jpg').open,
  hidden: false
)
