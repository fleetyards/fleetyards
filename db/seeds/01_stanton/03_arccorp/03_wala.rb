# frozen_string_literal: true

wala = CelestialObject.find_or_create_by!(name: 'Wala')
wala.update!(hidden: false)

area_061 = Station.find_or_initialize_by(name: 'ArcCrop Mining Area 061')
area_061.update!(
  celestial_object: wala,
  station_type: :outpost,
  location: 'Wala',
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/wala/area_061.jpg').open,
  hidden: false
)

area_048 = Station.find_or_initialize_by(name: 'ArcCrop Mining Area 048')
area_048.update!(
  celestial_object: wala,
  station_type: :outpost,
  location: 'Wala',
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/wala/area_048.jpg').open,
  hidden: false
)

area_045 = Station.find_or_initialize_by(name: 'ArcCrop Mining Area 045')
area_045.update!(
  celestial_object: wala,
  station_type: :outpost,
  location: 'Wala',
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/wala/area_045.jpg').open,
  hidden: false
)

area_056 = Station.find_or_initialize_by(name: 'ArcCrop Mining Area 056')
area_056.update!(
  celestial_object: wala,
  station_type: :outpost,
  location: 'Wala',
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/wala/area_056.jpg').open,
  hidden: false
)
