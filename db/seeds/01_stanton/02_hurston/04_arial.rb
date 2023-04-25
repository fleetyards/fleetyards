# frozen_string_literal: true

# TODO: take new image of Arial

arial = CelestialObject.find_or_create_by!(name: "Arial")
arial.update!(remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/arial/arial.jpg", hidden: false)

lathan = Station.find_or_initialize_by(name: "HDMS Lathan")
lathan.update!(
  celestial_object: arial,
  station_type: :outpost,
  location: nil,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/arial/lathan.jpg",
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: lathan)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/arial/lathan_admin.jpg",
  buying: true,
  selling: true,
  hidden: false
)

lathan.docks.destroy_all
{small: [1, 2]}.each do |ship_size, pads|
  pads.each do |pad|
    lathan.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size
    )
  end
end
{small: [1], medium: [2]}.each do |ship_size, pads|
  pads.each do |pad|
    lathan.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size
    )
  end
end

bezdek = Station.find_or_initialize_by(name: "HDMS Bezdek")
bezdek.update!(
  celestial_object: arial,
  station_type: :outpost,
  location: nil,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/arial/bezdek.jpg",
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: bezdek)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/arial/bezdek_admin.jpg",
  buying: true,
  selling: true,
  hidden: false
)

bezdek.docks.destroy_all
{small: [1, 2]}.each do |ship_size, pads|
  pads.each do |pad|
    bezdek.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size
    )
  end
end
{small: [1], medium: [2]}.each do |ship_size, pads|
  pads.each do |pad|
    bezdek.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size
    )
  end
end
