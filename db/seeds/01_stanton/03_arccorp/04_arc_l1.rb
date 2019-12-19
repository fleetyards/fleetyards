# frozen_string_literal: true

arccorp = CelestialObject.find_or_create_by!(name: 'ArcCorp')

hidden = false

arc_l1 = Station.find_or_initialize_by(name: 'Rest & Relax (ARC-L1)')
arc_l1.update!(
  celestial_object: arccorp,
  station_type: :rest_stop,
  location: 'ARC-L1',
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/arc-l1/arc-l1.jpg').open,
  hidden: hidden
)

arc_l1.docks.destroy_all
{ small: [1, 3], large: [2, 4] }.each do |ship_size, pads|
  pads.each do |pad|
    arc_l1.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end
{ large: [1, 2, 3, 4]}.each do |ship_size, hangars|
  hangars.each do |hangar|
    arc_l1.docks << Dock.new(
      name: ("%02d" % hangar),
      dock_type: :hangar,
      ship_size: ship_size,
    )
  end
end

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: arc_l1)
admin_office.update!(
  shop_type: :admin,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/arc-l1/admin.jpg').open,
  hidden: hidden
)

live_fire_weapons = Shop.find_or_initialize_by(name: 'Livefire Weapons', station: arc_l1)
live_fire_weapons.update!(
  shop_type: :weapons,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/arc-l1/weapons.jpg').open,
  hidden: hidden
)

casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: arc_l1)
casaba.update!(
  shop_type: :clothing,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/arc-l1/casaba.jpg').open,
  hidden: hidden
)
platinum_bay = Shop.find_or_initialize_by(name: 'Platinum Bay', station: arc_l1)
platinum_bay.update!(
  shop_type: :components,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/arc-l1/platinum.jpg').open,
  hidden: hidden
)
