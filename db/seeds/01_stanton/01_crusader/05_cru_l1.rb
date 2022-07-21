# frozen_string_literal: true

crusader = CelestialObject.find_or_create_by!(name: 'Crusader')

hidden = false

cru_l1 = Station.find_or_initialize_by(name: 'CRU-L1 Ambitious Dream Station')
cru_l1.update!(
  celestial_object: crusader,
  station_type: :station,
  classification: :rest_stop,
  location: 'CRU-L1',
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cru-l1/cru-l1-a.jpg',
  hidden: hidden
)

cru_l1.docks.destroy_all
{ small: [2, 3, 4], large: [1] }.each do |ship_size, pads|
  pads.each do |pad|
    cru_l1.docks << Dock.new(
      name: ('%02d' % pad),
      dock_type: :landingpad,
      ship_size: ship_size
    )
  end
end
{ large: [1, 2, 3, 4] }.each do |ship_size, hangars|
  hangars.each do |hangar|
    cru_l1.docks << Dock.new(
      name: ('%02d' % hangar),
      dock_type: :hangar,
      ship_size: ship_size
    )
  end
end
# { extra_large: [7] }.each do |ship_size, docks|
#   docks.each do |dock|
#     cru_l1.docks << Dock.new(
#       name: ("%02d" % dock),
#       dock_type: :dockingport,
#       ship_size: ship_size,
#     )
#   end
# end

cru_l1.habitations.destroy_all
%w[1 2 3 4 5].each do |level|
  pad = 1
  { container: 11 }.each do |hab_size, count|
    count.times do
      cru_l1.habitations << Habitation.new(
        name: "Hab #{level}#{'%02d' % pad}",
        habitation_name: 'EZ Hab',
        habitation_type: hab_size
      )
      pad += 1
    end
  end
end

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: cru_l1)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cru-l1/admin.jpg',
  buying: true,
  selling: true,
  hidden: hidden
)

Shop.find_by(name: 'Live Fire Weapons', station: cru_l1)&.destroy
bulwark_armor = Shop.find_or_initialize_by(name: 'Bulwark Armor', station: cru_l1)
bulwark_armor.update!(
  shop_type: :armor,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cru-l1/live_fire_weapons.jpg',
  selling: true,
  hidden: hidden
)

casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: cru_l1)
casaba.update!(
  shop_type: :clothing,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cru-l1/casaba.jpg',
  selling: true,
  hidden: hidden
)

platinum_bay = Shop.find_or_initialize_by(name: 'Platinum Bay', station: cru_l1)
platinum_bay.update!(
  shop_type: :components,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cru-l1/platinum_bay.jpg',
  selling: true,
  hidden: hidden
)
