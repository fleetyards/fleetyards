# frozen_string_literal: true

aberdeen = CelestialObject.find_or_create_by!(name: 'Aberdeen')
aberdeen.update!(store_image: Rails.root.join('db/seeds/images/stanton/hurston/aberdeen/aberdeen.jpg').open, hidden: false)

norgaard = Station.find_or_initialize_by(name: 'HDMS-Norgaard')
norgaard.update!(celestial_object: aberdeen, station_type: :outpost, location: 'Aberdeen', store_image: Rails.root.join('db/seeds/images/stanton/hurston/aberdeen/norgaard.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: norgaard)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/hurston/aberdeen/norgaard_admin.jpg').open, hidden: false)

norgaard.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    norgaard.docks << Dock.new(
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
    norgaard.docks << Dock.new(
      name: "Ladingpad #{"%02d" % pad}",
      dock_type: :landingpad,
      ship_size: ship_size,
    )
    pad += 1
  end
end

anderson = Station.find_or_initialize_by(name: 'HDMS-Anderson')
anderson.update!(celestial_object: aberdeen, station_type: :outpost, location: 'Aberdeen', store_image: Rails.root.join('db/seeds/images/stanton/hurston/aberdeen/anderson.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: anderson)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/hurston/aberdeen/anderson_admin.jpg').open, hidden: false)

anderson.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    anderson.docks << Dock.new(
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
    anderson.docks << Dock.new(
      name: "Ladingpad #{"%02d" % pad}",
      dock_type: :landingpad,
      ship_size: ship_size,
    )
    pad += 1
  end
end