# frozen_string_literal: true

# TODO: take new image of Aberdeen

aberdeen = CelestialObject.find_or_create_by!(name: "Aberdeen")
aberdeen.update!(remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/aberdeen/aberdeen.jpg", hidden: false)

norgaard = Station.find_or_initialize_by(name: "HDMS-Norgaard")
norgaard.update!(
  celestial_object: aberdeen,
  station_type: :outpost,
  location: nil,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/aberdeen/norgaard.jpg",
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: norgaard)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/aberdeen/norgaard_admin.jpg",
  buying: true,
  selling: true,
  hidden: false
)

norgaard.docks.destroy_all
{small: [1, 2]}.each do |ship_size, pads|
  pads.each do |pad|
    norgaard.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size
    )
  end
end
{small: [1], medium: [2]}.each do |ship_size, pads|
  pads.each do |pad|
    norgaard.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size
    )
  end
end

anderson = Station.find_or_initialize_by(name: "HDMS-Anderson")
anderson.update!(
  celestial_object: aberdeen,
  station_type: :outpost,
  location: nil,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/aberdeen/anderson.jpg",
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: anderson)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/aberdeen/anderson_admin.jpg",
  buying: true,
  selling: true,
  hidden: false
)

anderson.docks.destroy_all
{small: [1, 2]}.each do |ship_size, pads|
  pads.each do |pad|
    anderson.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size
    )
  end
end
{small: [1], medium: [2]}.each do |ship_size, pads|
  pads.each do |pad|
    anderson.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size
    )
  end
end
