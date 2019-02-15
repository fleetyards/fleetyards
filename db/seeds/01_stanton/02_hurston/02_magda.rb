# frozen_string_literal: true

magda = CelestialObject.find_or_create_by!(name: 'Magda')
magda.update!(store_image: Rails.root.join('db/seeds/images/stanton/hurston/magda/magda.jpg').open, hidden: false)

hahn = Station.find_or_initialize_by(name: 'HDMS-Hahn')
hahn.update!(celestial_object: magda, station_type: :outpost, location: 'Magda', store_image: Rails.root.join('db/seeds/images/stanton/hurston/magda/hahn.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: hahn)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/hurston/magda/hahn_admin.jpg').open, hidden: false)

hahn.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    hahn.docks << Dock.new(
      name: "Vehiclepad #{"%02d" % pad}",
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
    pad += 1
  end
end
pad = 1
{ medium: 1, large: 1 }.each do |ship_size, count|
  count.times do |index|
    hahn.docks << Dock.new(
      name: "Ladingpad #{"%02d" % pad}",
      dock_type: :landingpad,
      ship_size: ship_size,
    )
    pad += 1
  end
end

perlman = Station.find_or_initialize_by(name: 'HDMS-Perlman')
perlman.update!(celestial_object: magda, station_type: :outpost, location: 'Magda', store_image: Rails.root.join('db/seeds/images/stanton/hurston/magda/perlman.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: perlman)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/hurston/magda/perlman_admin.jpg').open, hidden: false)

perlman.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    perlman.docks << Dock.new(
      name: "Vehiclepad #{"%02d" % pad}",
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
    pad += 1
  end
end
pad = 1
{ medium: 1, large: 1 }.each do |ship_size, count|
  count.times do |index|
    perlman.docks << Dock.new(
      name: "Ladingpad #{"%02d" % pad}",
      dock_type: :landingpad,
      ship_size: ship_size,
    )
    pad += 1
  end
end