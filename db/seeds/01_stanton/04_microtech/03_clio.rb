# frozen_string_literal: true

clio = CelestialObject.find_or_create_by!(name: 'Clio')
clio.update!(store_image: Rails.root.join('db/seeds/images/stanton/microtech/clio/clio.jpg').open, hidden: false)

rayari_mc_grath = Station.find_or_initialize_by(name: 'Rayari McGrath Research Outpost')
rayari_mc_grath.update!(
  celestial_object: clio,
  station_type: :outpost,
  classification: :science,
  location: 'Clio',
  # store_image: Rails.root.join('db/seeds/images/stanton/hurston/stanhope.jpg').open,
  hidden: false
)

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: rayari_mc_grath)
admin_office.update!(
  shop_type: :admin,
  # store_image: Rails.root.join('db/seeds/images/stanton/hurston/stanhope_admin.jpg').open,
  buying: true,
  selling: true,
  hidden: false
)

rayari_mc_grath.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    rayari_mc_grath.docks << Dock.new(
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
    rayari_mc_grath.docks << Dock.new(
      name: "Ladingpad #{'%02d' % pad}",
      dock_type: :landingpad,
      ship_size: ship_size
    )
    pad += 1
  end
end

rayari_cantwell = Station.find_or_initialize_by(name: 'Rayari Cantwell Research Outpost')
rayari_cantwell.update!(
  celestial_object: clio,
  station_type: :outpost,
  classification: :science,
  location: 'Clio',
  # store_image: Rails.root.join('db/seeds/images/stanton/hurston/stanhope.jpg').open,
  hidden: false
)

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: rayari_cantwell)
admin_office.update!(
  shop_type: :admin,
  # store_image: Rails.root.join('db/seeds/images/stanton/hurston/stanhope_admin.jpg').open,
  buying: true,
  selling: true,
  hidden: false
)

rayari_cantwell.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    rayari_cantwell.docks << Dock.new(
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
    rayari_cantwell.docks << Dock.new(
      name: "Ladingpad #{'%02d' % pad}",
      dock_type: :landingpad,
      ship_size: ship_size
    )
    pad += 1
  end
end
