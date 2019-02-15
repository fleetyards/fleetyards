# frozen_string_literal: true

crusader = CelestialObject.find_or_create_by!(name: 'Crusader')
crusader.update!(store_image: Rails.root.join('db/seeds/images/stanton/crusader/crusader.jpg').open, hidden: false)

portolisar = Station.find_or_initialize_by(name: 'Port Olisar')
portolisar.update!(celestial_object: crusader, station_type: :hub, location: 'Orbit', store_image: Rails.root.join('db/seeds/images/stanton/crusader/portolisar/portolisar.jpg').open, hidden: false)
portolisar.docks.destroy_all
%w[A B C D].each do |strut|
  pad = 1
  { small: 8, medium: 2, extra_large: 1 }.each do |ship_size, count|
    count.times do
      portolisar.docks << Dock.new(
        name: "Ladingpad #{strut} #{"%02d" % pad}",
        dock_type: :landingpad,
        ship_size: ship_size,
      )
      pad += 1
    end
  end
end

portolisar.habitations.destroy_all
%w[A B C D].each do |strut|
  pad = 1
  { container: 16 }.each do |ship_size, count|
    count.times do
      portolisar.habitations << Habitation.new(
        name: "EZ Hab #{strut} #{"%02d" % pad}",
        habitation_type: :container
      )
      pad += 1
    end
  end
end

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: portolisar)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/crusader/portolisar/admin.jpg').open, hidden: false)
dumpers_depot = Shop.find_or_initialize_by(name: "Dumper's Depot", station: portolisar)
dumpers_depot.update!(shop_type: :components, store_image: Rails.root.join('db/seeds/images/stanton/crusader/portolisar/dumpers_depot.jpg').open, hidden: false)
live_fire_weapons = Shop.find_or_initialize_by(name: 'Live Fire Weapons', station: portolisar)
live_fire_weapons.update!(shop_type: :weapons, store_image: Rails.root.join('db/seeds/images/stanton/crusader/portolisar/live_fire_weapons.jpg').open, hidden: false)
garrity_defense = Shop.find_or_initialize_by(name: 'Garrity Defense', station: portolisar)
garrity_defense.update!(shop_type: :armor, store_image: Rails.root.join('db/seeds/images/stanton/crusader/portolisar/garrity_defense.jpg').open, hidden: false)
casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: portolisar)
casaba.update!(shop_type: :clothing, store_image: Rails.root.join('db/seeds/images/stanton/crusader/portolisar/casaba.jpg').open, hidden: false)

Station.where(name: 'Rest & Relax (CRU-L2)').destroy_all

r_n_r_cru_l1 = Station.find_or_initialize_by(name: 'Rest & Relax (CRU-L1)')
r_n_r_cru_l1.update!(celestial_object: crusader, station_type: :rest_stop, location: 'CRU-L1', store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l1/cru-l1.jpg').open, hidden: false)

r_n_r_cru_l1.docks.destroy_all
pad = 1
{ small: 3, large: 1 }.each do |ship_size, count|
  count.times do |index|
    r_n_r_cru_l1.docks << Dock.new(
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
    r_n_r_cru_l1.docks << Dock.new(
      name: "Hangar #{"%02d" % pad}",
      dock_type: :hangar,
      ship_size: ship_size,
    )
    pad += 1
  end
end
pad = 1
{ extra_large: 1 }.each do |ship_size, count|
  count.times do |index|
    r_n_r_cru_l1.docks << Dock.new(
      name: "Dockingport #{"%02d" % pad}",
      dock_type: :dockingport,
      ship_size: ship_size,
    )
    pad += 1
  end
end

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: r_n_r_cru_l1)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l1/admin.jpg').open, hidden: false)
live_fire_weapons = Shop.find_or_initialize_by(name: 'Livefire Weapons', station: r_n_r_cru_l1)
live_fire_weapons.update!(shop_type: :weapons, store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l1/live_fire_weapons.jpg').open, hidden: false)
casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: r_n_r_cru_l1)
casaba.update!(shop_type: :clothing, store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l1/casaba.jpg').open, hidden: false)
platinum_bay = Shop.find_or_initialize_by(name: 'Platinum Bay', station: r_n_r_cru_l1)
platinum_bay.update!(shop_type: :components, store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l1/platinum_bay.jpg').open, hidden: false)

r_n_r_cru_l2 = Station.find_or_initialize_by(name: 'Rest & Relax (CRU-L2)')
r_n_r_cru_l2.update!(celestial_object: crusader, station_type: :rest_stop, location: 'CRU-L2', hidden: true)

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: r_n_r_cru_l2)
admin_office.update!(shop_type: :admin, hidden: true)
live_fire_weapons = Shop.find_or_initialize_by(name: 'Livefire Weapons', station: r_n_r_cru_l2)
live_fire_weapons.update!(shop_type: :weapons, hidden: true)
casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: r_n_r_cru_l2)
casaba.update!(shop_type: :clothing, hidden: true)
platinum_bay = Shop.find_or_initialize_by(name: 'Platinum Bay', station: r_n_r_cru_l2)
platinum_bay.update!(shop_type: :components, hidden: true)

r_n_r_cru_l3 = Station.find_or_initialize_by(name: 'Rest & Relax (CRU-L3)')
r_n_r_cru_l3.update!(celestial_object: crusader, station_type: :rest_stop, location: 'CRU-L3', hidden: true)

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: r_n_r_cru_l3)
admin_office.update!(shop_type: :admin, hidden: true)
live_fire_weapons = Shop.find_or_initialize_by(name: 'Livefire Weapons', station: r_n_r_cru_l3)
live_fire_weapons.update!(shop_type: :weapons, hidden: true)
casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: r_n_r_cru_l3)
casaba.update!(shop_type: :clothing, hidden: true)
platinum_bay = Shop.find_or_initialize_by(name: 'Platinum Bay', station: r_n_r_cru_l3)
platinum_bay.update!(shop_type: :components, hidden: true)

r_n_r_cru_l4 = Station.find_or_initialize_by(name: 'Rest & Relax (CRU-L4)')
r_n_r_cru_l4.update!(celestial_object: crusader, station_type: :rest_stop, location: 'CRU-L4', store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l4/cru-l4.jpg').open, hidden: false)

r_n_r_cru_l4.docks.destroy_all
pad = 1
{ small: 1, medium: 3 }.each do |ship_size, count|
  count.times do |index|
    r_n_r_cru_l4.docks << Dock.new(
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
    r_n_r_cru_l4.docks << Dock.new(
      name: "Hangar #{"%02d" % pad}",
      dock_type: :hangar,
      ship_size: ship_size,
    )
    pad += 1
  end
end

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: r_n_r_cru_l4)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l4/admin.jpg').open, hidden: false)
live_fire_weapons = Shop.find_or_initialize_by(name: 'Livefire Weapons', station: r_n_r_cru_l4)
live_fire_weapons.update!(shop_type: :weapons, store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l4/weapons.jpg').open,hidden: false)
casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: r_n_r_cru_l4)
casaba.update!(shop_type: :clothing, store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l4/casaba.jpg').open,hidden: false)
platinum_bay = Shop.find_or_initialize_by(name: 'Platinum Bay', station: r_n_r_cru_l4)
platinum_bay.update!(shop_type: :components, store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l4/platinum.jpg').open,hidden: false)

r_n_r_cru_l5 = Station.find_or_initialize_by(name: 'Rest & Relax (CRU-L5)')
r_n_r_cru_l5.update!(celestial_object: crusader, station_type: :rest_stop, location: 'CRU-L5', store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l5/cru-l5.jpg').open, hidden: false)

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: r_n_r_cru_l5)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l5/admin.jpg').open, hidden: false)
live_fire_weapons = Shop.find_or_initialize_by(name: 'Livefire Weapons', station: r_n_r_cru_l5)
live_fire_weapons.update!(shop_type: :weapons, store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l5/weapons.jpg').open, hidden: false)
casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: r_n_r_cru_l5)
casaba.update!(shop_type: :clothing, store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l5/casaba.jpg').open, hidden: false)
platinum_bay = Shop.find_or_initialize_by(name: 'Platinum Bay', station: r_n_r_cru_l5)
platinum_bay.update!(shop_type: :components, store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l5/platinum.jpg').open, hidden: false)