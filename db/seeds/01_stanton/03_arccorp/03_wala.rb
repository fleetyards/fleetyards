# frozen_string_literal: true

wala = CelestialObject.find_or_create_by!(name: 'Wala')
wala.update!(store_image: Rails.root.join('db/seeds/images/stanton/arccorp/wala/wala.jpg').open, hidden: false)

area_061 = Station.find_or_initialize_by(name: 'ArcCrop Mining Area 061')
area_061.update!(
  celestial_object: wala,
  station_type: :outpost,
  location: nil,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/wala/area_061.jpg').open,
  hidden: false
)

area_061.docks.destroy_all
{ small: [1, 2] }.each do |ship_size, pads|
  pads.each do |pad|
    area_061.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
  end
end
{ medium: [1] }.each do |ship_size, pads|
  pads.each do |pad|
    area_061.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end

admin_office_area_061 = Shop.find_or_initialize_by(name: 'Admin Office', station: area_061)
admin_office_area_061.update!(
  shop_type: :admin,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/wala/area_061_admin.jpg').open,
  hidden: false
)

area_048 = Station.find_or_initialize_by(name: 'ArcCrop Mining Area 048')
area_048.update!(
  celestial_object: wala,
  station_type: :outpost,
  location: nil,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/wala/area_048.jpg').open,
  hidden: false
)

admin_office_area_048 = Shop.find_or_initialize_by(name: 'Admin Office', station: area_048)
admin_office_area_048.update!(
  shop_type: :admin,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/wala/area_048_admin.jpg').open,
  hidden: false
)

area_048.docks.destroy_all
{ small: [1, 2] }.each do |ship_size, pads|
  pads.each do |pad|
    area_048.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
  end
end
{ medium: [1] }.each do |ship_size, pads|
  pads.each do |pad|
    area_048.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end

area_045 = Station.find_or_initialize_by(name: 'ArcCrop Mining Area 045')
area_045.update!(
  celestial_object: wala,
  station_type: :outpost,
  location: nil,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/wala/area_045.jpg').open,
  hidden: false
)

admin_office_area_045 = Shop.find_or_initialize_by(name: 'Admin Office', station: area_045)
admin_office_area_045.update!(
  shop_type: :admin,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/wala/area_045_admin.jpg').open,
  hidden: false
)

area_045.docks.destroy_all
{ small: [1, 2] }.each do |ship_size, pads|
  pads.each do |pad|
    area_045.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
  end
end
{ medium: [1] }.each do |ship_size, pads|
  pads.each do |pad|
    area_045.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end

area_056 = Station.find_or_initialize_by(name: 'ArcCrop Mining Area 056')
area_056.update!(
  celestial_object: wala,
  station_type: :outpost,
  location: nil,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/wala/area_056.jpg').open,
  hidden: false
)

admin_office_area_056 = Shop.find_or_initialize_by(name: 'Admin Office', station: area_056)
admin_office_area_056.update!(
  shop_type: :admin,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/wala/area_056_admin.jpg').open,
  hidden: false
)

area_056.docks.destroy_all
{ small: [1, 2] }.each do |ship_size, pads|
  pads.each do |pad|
    area_056.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
  end
end
{ medium: [1] }.each do |ship_size, pads|
  pads.each do |pad|
    area_056.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end
