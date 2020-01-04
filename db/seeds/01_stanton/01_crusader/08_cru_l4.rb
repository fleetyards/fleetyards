# frozen_string_literal: true

crusader = CelestialObject.find_or_create_by!(name: 'Crusader')

hidden = false

cru_l4 = Station.find_or_initialize_by(name: 'Rest & Relax (CRU-L4)')
cru_l4.update!(
  celestial_object: crusader,
  station_type: :rest_stop,
  location: 'CRU-L4',
  store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l4/cru-l4-a.jpg').open,
  hidden: hidden
)

cru_l4.docks.destroy_all
{ small: [3, 4, 5, 6], medium: [1, 2, 7, 8] }.each do |ship_size, pads|
  pads.each do |pad|
    cru_l4.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end
{ large: [1, 2] }.each do |ship_size, hangars|
  hangars.each do |hangar|
    cru_l4.docks << Dock.new(
      name: ("%02d" % hangar),
      dock_type: :hangar,
      ship_size: ship_size,
    )
  end
end

cru_l4.habitations.destroy_all
%w[1 2 3 4 5].each do |level|
  pad = 1
  { container: 11 }.each do |hab_size, count|
    count.times do
      cru_l4.habitations << Habitation.new(
        name: "Hab #{level}#{"%02d" % pad}",
        habitation_name: 'EZ Hab',
        habitation_type: hab_size
      )
      pad += 1
    end
  end
end

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: cru_l4)
admin_office.update!(
  shop_type: :admin,
  store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l4/admin.jpg').open,
  hidden: hidden
)

live_fire_weapons = Shop.find_or_initialize_by(name: 'Livefire Weapons', station: cru_l4)
live_fire_weapons.update!(
  shop_type: :weapons,
  store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l4/weapons.jpg').open,
  hidden: hidden
)

casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: cru_l4)
casaba.update!(
  shop_type: :clothing,
  store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l4/casaba.jpg').open,
  hidden: hidden
)

platinum_bay = Shop.find_or_initialize_by(name: 'Platinum Bay', station: cru_l4)
platinum_bay.update!(
  shop_type: :components,
  store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l4/platinum.jpg').open,
  hidden: hidden
)
