# frozen_string_literal: true

crusader = CelestialObject.find_or_create_by!(name: 'Crusader')

hidden = false

portolisar = Station.find_or_initialize_by(name: 'Port Olisar')
portolisar.update!(
  celestial_object: crusader,
  station_type: :station,
  classification: :trading,
  location: nil,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/portolisar/portolisar.jpg',
  hidden: false,
  refinery: true
)

portolisar.docks.destroy_all
%w[A B C D].each do |strut|
  { small: [1, 2, 3, 4, 5, 6, 7, 8], medium: [9, 10], extra_large: [0] }.each do |ship_size, pads|
    pads.each do |pad|
      portolisar.docks << Dock.new(
        name: ("%02d" % pad),
        group: "Strut #{strut}",
        dock_type: :landingpad,
        ship_size: ship_size,
      )
    end
  end
end

portolisar.habitations.destroy_all
%w[A B C D].each do |strut|
  pad = 1
  { container: 16 }.each do |ship_size, count|
    count.times do
      portolisar.habitations << Habitation.new(
        name: ("%02d" % pad),
        habitation_name: "EZ Hab #{strut}",
        habitation_type: :container
      )
      pad += 1
    end
  end
end

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: portolisar)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/portolisar/admin.jpg',
  buying: true,
  selling: true,
  hidden: hidden
)

dumpers_depot = Shop.find_or_initialize_by(name: "Dumper's Depot", station: portolisar)
dumpers_depot.update!(
  shop_type: :components,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/portolisar/dumpers_depot.jpg',
  selling: true,
  hidden: hidden
)

live_fire_weapons = Shop.find_or_initialize_by(name: 'Live Fire Weapons', station: portolisar)
live_fire_weapons.update!(
  shop_type: :weapons,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/portolisar/live_fire_weapons.jpg',
  selling: true,
  hidden: hidden
)

garrity_defense = Shop.find_or_initialize_by(name: 'Garrity Defense', station: portolisar)
garrity_defense.update!(
  shop_type: :armor,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/portolisar/garrity_defense.jpg',
  selling: true,
  hidden: hidden
)

casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: portolisar)
casaba.update!(
  shop_type: :clothing,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/portolisar/casaba.jpg',
  selling: true,
  hidden: hidden
)
