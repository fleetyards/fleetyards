# frozen_string_literal: true

crusader = CelestialObject.find_or_create_by!(name: 'Crusader')

hidden = false

cru_l1 = Station.find_or_initialize_by(name: 'Rest & Relax (CRU-L1)')
cru_l1.update!(
  celestial_object: crusader,
  station_type: :rest_stop,
  location: 'CRU-L1',
  store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l1/cru-l1-a.jpg').open,
  hidden: hidden
)

cru_l1.docks.destroy_all
{ small: [2, 3, 4], large: [1] }.each do |ship_size, pads|
  pads.each do |pad|
    cru_l1.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end
{ large: [1, 2, 3, 4] }.each do |ship_size, hangars|
  hangars.each do |hangar|
    cru_l1.docks << Dock.new(
      name: ("%02d" % hangar),
      dock_type: :hangar,
      ship_size: ship_size,
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
        name: "Hab #{level}#{"%02d" % pad}",
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
  store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l1/admin.jpg').open,
  hidden: hidden
)

live_fire_weapons = Shop.find_or_initialize_by(name: 'Livefire Weapons', station: cru_l1)
live_fire_weapons.update!(
  shop_type: :weapons,
  store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l1/live_fire_weapons.jpg').open,
  hidden: hidden
)

casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: cru_l1)
casaba.update!(
  shop_type: :clothing,
  store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l1/casaba.jpg').open,
  hidden: hidden
)

platinum_bay = Shop.find_or_initialize_by(name: 'Platinum Bay', station: cru_l1)
platinum_bay.update!(
  shop_type: :components,
  store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l1/platinum_bay.jpg').open,
  hidden: hidden
)
