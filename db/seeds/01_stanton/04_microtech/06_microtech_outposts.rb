microtech = CelestialObject.find_or_create_by!(name: 'microTech')

shubin_sm0_13 = Station.find_or_initialize_by(name: 'Shubin Mining Facility SM0-13')
shubin_sm0_13.update!(
  celestial_object: microtech,
  station_type: :outpost,
  classification: :mining,
  location: 'Microtech',
  # store_image: Rails.root.join('db/seeds/images/stanton/hurston/stanhope.jpg').open,
  hidden: false
)

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: shubin_sm0_13)
admin_office.update!(
  shop_type: :admin,
  # store_image: Rails.root.join('db/seeds/images/stanton/hurston/stanhope_admin.jpg').open,
  buying: true,
  selling: true,
  hidden: false
)

shubin_sm0_13.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    shubin_sm0_13.docks << Dock.new(
      name: "Vehiclepad #{'%02d' % pad}",
      dock_type: :vehiclepad,
      ship_size: ship_size
    )
    pad += 1
  end
end
pad = 1
{ medium: 1, large: 1 }.each do |ship_size, count|
  count.times do |_index|
    shubin_sm0_13.docks << Dock.new(
      name: "Ladingpad #{'%02d' % pad}",
      dock_type: :landingpad,
      ship_size: ship_size
    )
    pad += 1
  end
end

shubin_sm0_10 = Station.find_or_initialize_by(name: 'Shubin Mining Facility SM0-10')
shubin_sm0_10.update!(
  celestial_object: microtech,
  station_type: :outpost,
  classification: :mining,
  location: 'Microtech',
  # store_image: Rails.root.join('db/seeds/images/stanton/hurston/stanhope.jpg').open,
  hidden: false
)

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: shubin_sm0_10)
admin_office.update!(
  shop_type: :admin,
  # store_image: Rails.root.join('db/seeds/images/stanton/hurston/stanhope_admin.jpg').open,
  buying: true,
  selling: true,
  hidden: false
)

shubin_sm0_10.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    shubin_sm0_10.docks << Dock.new(
      name: "Vehiclepad #{'%02d' % pad}",
      dock_type: :vehiclepad,
      ship_size: ship_size
    )
    pad += 1
  end
end
pad = 1
{ medium: 1, large: 1 }.each do |ship_size, count|
  count.times do |_index|
    shubin_sm0_10.docks << Dock.new(
      name: "Ladingpad #{'%02d' % pad}",
      dock_type: :landingpad,
      ship_size: ship_size
    )
    pad += 1
  end
end

shubin_sm0_18 = Station.find_or_initialize_by(name: 'Shubin Mining Facility SM0-18')
shubin_sm0_18.update!(
  celestial_object: microtech,
  station_type: :outpost,
  classification: :mining,
  location: 'Microtech',
  # store_image: Rails.root.join('db/seeds/images/stanton/hurston/stanhope.jpg').open,
  hidden: false
)

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: shubin_sm0_18)
admin_office.update!(
  shop_type: :admin,
  # store_image: Rails.root.join('db/seeds/images/stanton/hurston/stanhope_admin.jpg').open,
  buying: true,
  selling: true,
  hidden: false
)

shubin_sm0_18.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    shubin_sm0_18.docks << Dock.new(
      name: "Vehiclepad #{'%02d' % pad}",
      dock_type: :vehiclepad,
      ship_size: ship_size
    )
    pad += 1
  end
end
pad = 1
{ medium: 1, large: 1 }.each do |ship_size, count|
  count.times do |_index|
    shubin_sm0_18.docks << Dock.new(
      name: "Ladingpad #{'%02d' % pad}",
      dock_type: :landingpad,
      ship_size: ship_size
    )
    pad += 1
  end
end


shubin_sm0_22 = Station.find_or_initialize_by(name: 'Shubin Mining Facility SM0-22')
shubin_sm0_22.update!(
  celestial_object: microtech,
  station_type: :outpost,
  classification: :mining,
  location: 'Microtech',
  # store_image: Rails.root.join('db/seeds/images/stanton/hurston/stanhope.jpg').open,
  hidden: false
)

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: shubin_sm0_22)
admin_office.update!(
  shop_type: :admin,
  # store_image: Rails.root.join('db/seeds/images/stanton/hurston/stanhope_admin.jpg').open,
  buying: true,
  selling: true,
  hidden: false
)

shubin_sm0_22.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    shubin_sm0_22.docks << Dock.new(
      name: "Vehiclepad #{'%02d' % pad}",
      dock_type: :vehiclepad,
      ship_size: ship_size
    )
    pad += 1
  end
end
pad = 1
{ medium: 1, large: 1 }.each do |ship_size, count|
  count.times do |_index|
    shubin_sm0_22.docks << Dock.new(
      name: "Ladingpad #{'%02d' % pad}",
      dock_type: :landingpad,
      ship_size: ship_size
    )
    pad += 1
  end
end

rayari_deltana = Station.find_or_initialize_by(name: 'Rayari Deltana Research Outpost')
rayari_deltana.update!(
  celestial_object: microtech,
  station_type: :outpost,
  classification: :science,
  location: 'Microtech',
  # store_image: Rails.root.join('db/seeds/images/stanton/hurston/stanhope.jpg').open,
  hidden: false
)

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: rayari_deltana)
admin_office.update!(
  shop_type: :admin,
  # store_image: Rails.root.join('db/seeds/images/stanton/hurston/stanhope_admin.jpg').open,
  buying: true,
  selling: true,
  hidden: false
)

rayari_deltana.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    rayari_deltana.docks << Dock.new(
      name: "Vehiclepad #{'%02d' % pad}",
      dock_type: :vehiclepad,
      ship_size: ship_size
    )
    pad += 1
  end
end
pad = 1
{ medium: 1, large: 1 }.each do |ship_size, count|
  count.times do |_index|
    rayari_deltana.docks << Dock.new(
      name: "Ladingpad #{'%02d' % pad}",
      dock_type: :landingpad,
      ship_size: ship_size
    )
    pad += 1
  end
end

point_wain = Station.find_or_initialize_by(name: 'Point Wain Emergency Shelter')
point_wain.update!(
  celestial_object: microtech,
  station_type: :aid_shelter,
  location: nil,
  # store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/tamdon.jpg').open,
  hidden: false
)

clear_view = Station.find_or_initialize_by(name: 'Clear View Emergency Shelter')
clear_view.update!(
  celestial_object: microtech,
  station_type: :aid_shelter,
  location: nil,
  # store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/tamdon.jpg').open,
  hidden: false
)

nuiqsut = Station.find_or_initialize_by(name: 'Nuiqsut Emergency Shelter')
nuiqsut.update!(
  celestial_object: microtech,
  station_type: :aid_shelter,
  location: nil,
  # store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/tamdon.jpg').open,
  hidden: false
)

calhoun = Station.find_or_initialize_by(name: 'Calhoun Pass Emergency Shelter')
calhoun.update!(
  celestial_object: microtech,
  station_type: :aid_shelter,
  location: nil,
  # store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/tamdon.jpg').open,
  hidden: false
)
