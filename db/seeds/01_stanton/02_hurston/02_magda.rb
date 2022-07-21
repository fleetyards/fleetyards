# frozen_string_literal: true

magda = CelestialObject.find_or_create_by!(name: 'Magda')
magda.update!(remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/magda/magda.jpg', hidden: false)

hahn = Station.find_or_initialize_by(name: 'HDMS Hahn')
hahn.update!(
  celestial_object: magda,
  station_type: :outpost,
  location: nil,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/magda/hahn.jpg',
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: hahn)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/magda/hahn_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)

hahn.docks.destroy_all
{ small: [1, 2] }.each do |ship_size, pads|
  pads.each do |pad|
    hahn.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
  end
end
{ small: [1],  medium: [2] }.each do |ship_size, pads|
  pads.each do |pad|
    hahn.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end

perlman = Station.find_or_initialize_by(name: 'HDMS Perlman')
perlman.update!(
  celestial_object: magda,
  station_type: :outpost,
  location: nil,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/magda/perlman.jpg',
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: perlman)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/magda/perlman_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)

perlman.docks.destroy_all
{ small: [1, 2] }.each do |ship_size, pads|
  pads.each do |pad|
    perlman.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
  end
end
{ small: [1],  medium: [2] }.each do |ship_size, pads|
  pads.each do |pad|
    perlman.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end
