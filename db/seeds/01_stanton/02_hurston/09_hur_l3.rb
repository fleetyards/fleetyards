# frozen_string_literal: true

# TODO: update screenshot and docks

hurston = CelestialObject.find_or_create_by!(name: 'Hurston')

hidden = false

hur_l3 = Station.find_or_initialize_by(name: 'Rest & Relax (HUR-L3)')
hur_l3.update!(celestial_object: hurston, station_type: :rest_stop, location: 'HUR-L3', store_image: Rails.root.join('db/seeds/images/stanton/hurston/hur-l3/hur-l3-a.jpg').open, hidden: false)

hur_l3.docks.destroy_all
pad = 1
{ medium: 4 }.each do |ship_size, count|
  count.times do |index|
    hur_l3.docks << Dock.new(
      name: "Ladingpad #{"%02d" % pad}",
      dock_type: :landingpad,
      ship_size: ship_size,
    )
    pad += 1
  end
end
pad = 1
{ large: 2 }.each do |ship_size, count|
  count.times do |index|
    hur_l3.docks << Dock.new(
      name: "Hangar #{"%02d" % pad}",
      dock_type: :hangar,
      ship_size: ship_size,
    )
    pad += 1
  end
end

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: hur_l3)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/hurston/hur-l3/admin.jpg').open, hidden: false)
live_fire_weapons = Shop.find_or_initialize_by(name: 'Livefire Weapons', station: hur_l3)
live_fire_weapons.update!(shop_type: :weapons, store_image: Rails.root.join('db/seeds/images/stanton/hurston/hur-l3/weapons.jpg').open, hidden: false)
casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: hur_l3)
casaba.update!(shop_type: :clothing, store_image: Rails.root.join('db/seeds/images/stanton/hurston/hur-l3/casaba.jpg').open, hidden: false)
platinum_bay = Shop.find_or_initialize_by(name: 'Platinum Bay', station: hur_l3)
platinum_bay.update!(shop_type: :components, store_image: Rails.root.join('db/seeds/images/stanton/hurston/hur-l3/platinum.jpg').open, hidden: false)
