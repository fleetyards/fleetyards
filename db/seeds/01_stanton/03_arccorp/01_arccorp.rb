# frozen_string_literal: true

arccorp = CelestialObject.find_or_create_by!(name: "ArcCorp")
arccorp.update!(
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/arccorp.png",
  hidden: false
)

area18 = Station.find_or_initialize_by(name: "Area 18")
area18.update!(
  celestial_object: arccorp,
  station_type: :landing_zone,
  location: nil,
  classification: :city,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/area18-1.jpg",
  hidden: false
)

area18.docks.destroy_all
{small: [1, 2, 3], medium: [4, 5, 6], large: [7, 8], capital: [9, 10, 11, 12]}.each do |ship_size, hangars|
  hangars.each do |hangar|
    area18.docks << Dock.new(
      name: ("%02d" % hangar),
      dock_type: :hangar,
      ship_size: ship_size
    )
  end
end

area18.habitations.destroy_all
%w[1 2 3 4 5 6].each do |level|
  pad = 1
  {small_apartment: 10}.each do |apartment_size, count|
    count.times do
      area18.habitations << Habitation.new(
        name: "Level #{"%02d" % level} Apartment #{"%02d" % pad}",
        habitation_name: "Adira Falls Apartments",
        habitation_type: apartment_size
      )
      pad += 1
    end
  end
end

astro = Shop.find_or_initialize_by(name: "Astro Armada", station: area18)
astro.update!(
  shop_type: :ships,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/area18/astro.jpg",
  selling: true,
  hidden: false
)

dumpers_depot = Shop.find_or_initialize_by(name: "Dumper's Depot", station: area18)
dumpers_depot.update!(
  shop_type: :components,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/area18/dumpers_depot.jpg",
  selling: true,
  hidden: false
)

casaba = Shop.find_or_initialize_by(name: "Casaba Outlet", station: area18)
casaba.update!(
  shop_type: :clothing,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/area18/casaba.jpg",
  selling: true,
  hidden: false
)

cubby_blast = Shop.find_or_initialize_by(name: "Cubby Blast", station: area18)
cubby_blast.update!(
  shop_type: :armor_and_weapons,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/area18/weapons.jpg",
  selling: true,
  hidden: false
)

gloc = Shop.find_or_initialize_by(name: "G-LOC Bar", station: area18)
gloc.update!(
  shop_type: :bar,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/area18/g-loc.jpg",
  hidden: false
)

tdd = Shop.find_or_initialize_by(name: "Trade & Development Division", station: area18)
tdd.update!(
  shop_type: :resources,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/area18/jobwell.jpg",
  buying: true,
  selling: true,
  hidden: false
)

arccorp_tower = Shop.find_or_initialize_by(name: "IO-North Tower", station: area18)
arccorp_tower.update!(
  shop_type: :admin,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/area18/admin.jpg",
  buying: true,
  selling: true,
  hidden: false
)

centermass = Shop.find_or_initialize_by(name: "CenterMass", station: area18)
centermass.update!(
  shop_type: :weapons,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/area18/centermass.jpg",
  selling: true,
  hidden: false
)

traveler_rentals = Shop.find_or_initialize_by(name: "Traveler Rentals", station: area18)
traveler_rentals.update!(
  shop_type: :rental,
  location: "Riker Memorial Spaceport",
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/traveler-rentals.jpg",
  rental: true,
  hidden: false
)

area04 = Station.find_or_initialize_by(name: "Area 04")
area04.update!(
  celestial_object: arccorp,
  station_type: :district,
  location: "ArcCorp",
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/area04.jpg',
  hidden: true
)

area06 = Station.find_or_initialize_by(name: "Area 06")
area06.update!(
  celestial_object: arccorp,
  station_type: :district,
  location: "ArcCorp",
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/area06.jpg',
  hidden: true
)

area11 = Station.find_or_initialize_by(name: "Area 11")
area11.update!(
  celestial_object: arccorp,
  station_type: :district,
  location: "ArcCorp",
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/area11.jpg',
  hidden: true
)

area17 = Station.find_or_initialize_by(name: "Area 17")
area17.update!(
  celestial_object: arccorp,
  station_type: :district,
  location: "ArcCorp",
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/area17.jpg',
  hidden: true
)

area20 = Station.find_or_initialize_by(name: "Area 20")
area20.update!(
  celestial_object: arccorp,
  station_type: :district,
  location: "ArcCorp",
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/area20.jpg',
  hidden: true
)
