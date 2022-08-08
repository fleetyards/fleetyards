# frozen_string_literal: true

crusader = CelestialObject.find_or_create_by!(name: 'Crusader')

hidden = false

cru_l5 = Station.find_or_initialize_by(name: 'CRU-L5 Beautiful Glen Station')
cru_l5.update!(
  celestial_object: crusader,
  station_type: :station,
  classification: :rest_stop,
  location: 'CRU-L5',
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cru-l5/cru-l5-a.jpg',
  hidden: hidden
)

cru_l5.docks.destroy_all
{ small: [1, 3], medium: [2, 4] }.each do |ship_size, pads|
  pads.each do |pad|
    cru_l5.docks << Dock.new(
      name: ('%02d' % pad),
      dock_type: :landingpad,
      ship_size: ship_size
    )
  end
end
{ large: [1, 2] }.each do |ship_size, hangars|
  hangars.each do |hangar|
    cru_l5.docks << Dock.new(
      name: ('%02d' % hangar),
      dock_type: :hangar,
      ship_size: ship_size
    )
  end
end

cru_l5.habitations.destroy_all
%w[1 2 3 4 5].each do |level|
  pad = 1
  { container: 11 }.each do |hab_size, count|
    count.times do
      cru_l5.habitations << Habitation.new(
        name: "Hab #{level}#{'%02d' % pad}",
        habitation_name: 'EZ Hab',
        habitation_type: hab_size
      )
      pad += 1
    end
  end
end

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: cru_l5)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cru-l5/admin.jpg',
  buying: true,
  selling: true,
  hidden: hidden
)

blackmarket = Shop.find_or_initialize_by(name: 'Blackmarket Terminal', station: cru_l5)
blackmarket.update!(
  shop_type: :blackmarket,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cru-l5/blackmarket.jpg',
  buying: true,
  selling: true,
  hidden: hidden
)

live_fire_weapons = Shop.find_or_initialize_by(name: 'Live Fire Weapons', station: cru_l5)
live_fire_weapons.update!(
  shop_type: :weapons,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cru-l5/weapons.jpg',
  selling: true,
  hidden: hidden
)

casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: cru_l5)
casaba.update!(
  shop_type: :clothing,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cru-l5/casaba.jpg',
  selling: true,
  hidden: hidden
)

platinum_bay = Shop.find_or_initialize_by(name: 'Platinum Bay', station: cru_l5)
platinum_bay.update!(
  shop_type: :components,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cru-l5/platinum.jpg',
  selling: true,
  hidden: hidden
)

congreve_weapons = Shop.find_or_initialize_by(name: 'Congreve Weapons', station: cru_l5)
congreve_weapons.update!(
  shop_type: :weapons,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/cur-l5/ship_weapons.jpg',
  selling: true,
  hidden: hidden
)
