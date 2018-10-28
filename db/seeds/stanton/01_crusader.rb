# frozen_string_literal: true

crusader = CelestialObject.find_or_create_by!(name: 'Crusader')
crusader.update!(store_image: Rails.root.join('db/seeds/images/crusader/crusader.jpg').open, hidden: false)

portolisar = Station.find_or_initialize_by(name: 'Port Olisar')
portolisar.update!(celestial_object: crusader, station_type: :hub, location: 'Orbit', store_image: Rails.root.join('db/seeds/images/crusader/portolisar.jpg').open, hidden: false)
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
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/crusader/admin_portolisar.jpg').open, hidden: false)
dumpers_depot = Shop.find_or_initialize_by(name: "Dumper's Depot", station: portolisar)
dumpers_depot.update!(shop_type: :components, store_image: Rails.root.join('db/seeds/images/crusader/dumpers_depot_portolisar.jpg').open, hidden: false)
live_fire_weapons = Shop.find_or_initialize_by(name: 'Live Fire Weapons', station: portolisar)
live_fire_weapons.update!(shop_type: :weapons, store_image: Rails.root.join('db/seeds/images/crusader/live_fire_weapons_portolisar.jpg').open, hidden: false)
garrity_defense = Shop.find_or_initialize_by(name: 'Garrity Defense', station: portolisar)
garrity_defense.update!(shop_type: :armor, store_image: Rails.root.join('db/seeds/images/crusader/garrity_defense_portolisar.jpg').open, hidden: false)
casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: portolisar)
casaba.update!(shop_type: :clothing, store_image: Rails.root.join('db/seeds/images/crusader/casaba_portolisar.jpg').open, hidden: false)

r_n_r_cru_l2 = Station.find_or_initialize_by(name: 'Rest & Relax (CRU-L2)')
r_n_r_cru_l2.update!(celestial_object: crusader, station_type: :rest_stop, location: 'CRU-L2', store_image: Rails.root.join('db/seeds/images/crusader/r_n_r_cru-l2.jpg').open, hidden: false)

r_n_r_cru_l2.docks.destroy_all
pad = 1
{ medium: 2, large: 2 }.each do |ship_size, count|
  count.times do |index|
    r_n_r_cru_l2.docks << Dock.new(
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
    r_n_r_cru_l2.docks << Dock.new(
      name: "Hangar #{"%02d" % pad}",
      dock_type: :hangar,
      ship_size: ship_size,
    )
    pad += 1
  end
end

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: r_n_r_cru_l2)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/crusader/admin_r_n_r_cru-l2.jpg').open, hidden: false)
live_fire_weapons = Shop.find_or_initialize_by(name: 'Livefire Weapons', station: r_n_r_cru_l2)
live_fire_weapons.update!(shop_type: :weapons, store_image: Rails.root.join('db/seeds/images/crusader/live_fire_weapons_r_n_r_cru-l2.jpg').open, hidden: false)
casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: r_n_r_cru_l2)
casaba.update!(shop_type: :clothing, store_image: Rails.root.join('db/seeds/images/crusader/casaba_r_n_r_cru-l2.jpg').open, hidden: false)
platinum_bay = Shop.find_or_initialize_by(name: 'Platinum Bay', station: r_n_r_cru_l2)
platinum_bay.update!(shop_type: :components, store_image: Rails.root.join('db/seeds/images/crusader/platinum_bay_r_n_r_cru-l2.jpg').open, hidden: false)
