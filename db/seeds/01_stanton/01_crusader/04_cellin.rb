# frozen_string_literal: true

cellin = CelestialObject.find_or_create_by!(name: 'Cellin')
cellin.update!(store_image: Rails.root.join('db/seeds/images/stanton/crusader/cellin/cellin.jpg').open, hidden: false)

kareah = Station.find_or_initialize_by(name: 'Security Post Kareah')
kareah.update!(celestial_object: cellin, station_type: :station, location: 'Orbit', store_image: Rails.root.join('db/seeds/images/stanton/crusader/cellin/kareah.jpg').open, hidden: false)
kareah.docks.destroy_all
pad = 1
{ small: 6, medium: 1, large: 1 }.each do |ship_size, count|
  count.times do
    kareah.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
    pad += 1
  end
end

gallete = Station.find_or_initialize_by(name: 'Gallete Family Farms')
gallete.update!(celestial_object: cellin, station_type: :outpost, location: 'cellin', store_image: Rails.root.join('db/seeds/images/stanton/crusader/cellin/gallete.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: gallete)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/crusader/cellin/gallete_admin.jpg').open, hidden: false)

hickes = Station.find_or_initialize_by(name: 'Hickes Research Outpost')
hickes.update!(celestial_object: cellin, station_type: :outpost, location: 'cellin', store_image: Rails.root.join('db/seeds/images/stanton/crusader/cellin/hickes.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: hickes)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/crusader/cellin/hickes_admin.jpg').open, hidden: false)

hickes.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    hickes.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
    pad += 1
  end
end
pad = 1
{ medium: 1, large: 1 }.each do |ship_size, count|
  count.times do |index|
    hickes.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
    pad += 1
  end
end

terra_mills = Station.find_or_initialize_by(name: 'Terra Mills HydroFarm')
terra_mills.update!(celestial_object: cellin, station_type: :outpost, location: 'cellin', store_image: Rails.root.join('db/seeds/images/stanton/crusader/cellin/terra_mills.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: terra_mills)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/crusader/cellin/terra_mills_admin.jpg').open, hidden: false)

terra_mills.docks.destroy_all
pad = 1
{ small: 2 }.each do |ship_size, count|
  count.times do
    terra_mills.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
    pad += 1
  end
end
pad = 1
{ medium: 1, large: 1 }.each do |ship_size, count|
  count.times do |index|
    terra_mills.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
    pad += 1
  end
end

tram_n_myers = Station.find_or_initialize_by(name: 'Tram & Myers Mining')
tram_n_myers.update!(celestial_object: cellin, station_type: :outpost, location: 'cellin', store_image: Rails.root.join('db/seeds/images/stanton/crusader/cellin/tram_n_myers.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: tram_n_myers)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/crusader/cellin/tram_n_myers_admin.jpg').open, hidden: false)

ashburn = Station.find_or_initialize_by(name: 'Ashburn Channel Aid Shelter')
ashburn.update!(celestial_object: cellin, station_type: :aid_shelter, location: 'cellin', store_image: Rails.root.join('db/seeds/images/stanton/crusader/cellin/ashburn.jpg').open, hidden: false)

flanagan = Station.find_or_initialize_by(name: "Flanagan's Ravine Aid Shelter")
flanagan.update!(celestial_object: cellin, station_type: :aid_shelter, location: 'cellin', store_image: Rails.root.join('db/seeds/images/stanton/crusader/cellin/flanagan.jpg').open, hidden: false)

julep = Station.find_or_initialize_by(name: 'Julep Ravine Aid Shelter')
julep.update!(celestial_object: cellin, station_type: :aid_shelter, location: 'cellin', store_image: Rails.root.join('db/seeds/images/stanton/crusader/cellin/julep.jpg').open, hidden: false)

mogote = Station.find_or_initialize_by(name: 'Mogote Shelter')
mogote.update!(celestial_object: cellin, station_type: :aid_shelter, location: 'cellin', store_image: Rails.root.join('db/seeds/images/stanton/crusader/cellin/mogote.jpg').open, hidden: false)
