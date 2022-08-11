# frozen_string_literal: true

hurston = CelestialObject.find_or_create_by!(name: 'Hurston')

stanhope = Station.find_or_initialize_by(name: 'HDMS Stanhope')
stanhope.update!(
  celestial_object: hurston,
  station_type: :outpost,
  location: 'Hurston',
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/stanhope.jpg',
  hidden: false
)

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: stanhope)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/stanhope_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)

stanhope.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    stanhope.docks << Dock.new(
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
    stanhope.docks << Dock.new(
      name: "Ladingpad #{'%02d' % pad}",
      dock_type: :landingpad,
      ship_size: ship_size
    )
    pad += 1
  end
end

edmond = Station.find_or_initialize_by(name: 'HDMS Edmond')
edmond.update!(
  celestial_object: hurston,
  station_type: :outpost,
  location: 'Hurston',
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/edmond.jpg',
  hidden: false
)

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: edmond)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/edmond_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)

edmond.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    edmond.docks << Dock.new(
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
    edmond.docks << Dock.new(
      name: "Ladingpad #{'%02d' % pad}",
      dock_type: :landingpad,
      ship_size: ship_size
    )
    pad += 1
  end
end

hadley = Station.find_or_initialize_by(name: 'HDMS Hadley')
hadley.update!(
  celestial_object: hurston,
  station_type: :outpost,
  location: 'Hurston',
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/hadley.jpg',
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: hadley)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/hadley_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)

hadley.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    hadley.docks << Dock.new(
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
    hadley.docks << Dock.new(
      name: "Ladingpad #{'%02d' % pad}",
      dock_type: :landingpad,
      ship_size: ship_size
    )
    pad += 1
  end
end

oparei = Station.find_or_initialize_by(name: 'HDMS Oparei')
oparei.update!(
  celestial_object: hurston,
  station_type: :outpost,
  location: 'Hurston',
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/oparei.jpg',
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: oparei)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/oparei_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)

oparei.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    oparei.docks << Dock.new(
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
    oparei.docks << Dock.new(
      name: "Ladingpad #{'%02d' % pad}",
      dock_type: :landingpad,
      ship_size: ship_size
    )
    pad += 1
  end
end

pinewood = Station.find_or_initialize_by(name: 'HDMS Pinewood')
pinewood.update!(
  celestial_object: hurston,
  station_type: :outpost,
  location: 'Hurston',
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/pinewood.jpg',
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: pinewood)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/pinewood_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)

pinewood.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    pinewood.docks << Dock.new(
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
    pinewood.docks << Dock.new(
      name: "Ladingpad #{'%02d' % pad}",
      dock_type: :landingpad,
      ship_size: ship_size
    )
    pad += 1
  end
end

thedus = Station.find_or_initialize_by(name: 'HDMS Thedus')
thedus.update!(
  celestial_object: hurston,
  station_type: :outpost,
  location: 'Hurston',
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/thedus.jpg',
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: thedus)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/thedus_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)

thedus.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    thedus.docks << Dock.new(
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
    thedus.docks << Dock.new(
      name: "Ladingpad #{'%02d' % pad}",
      dock_type: :landingpad,
      ship_size: ship_size
    )
    pad += 1
  end
end

reclamation = Station.find_or_initialize_by(name: 'Reclamation & Disposal Orinth')
reclamation.update!(
  celestial_object: hurston,
  station_type: :outpost,
  classification: :salvaging,
  location: 'Hurston',
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/reclamation.jpg',
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: reclamation)
admin_office.update!(
  shop_type: :admin,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/reclamation_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)
