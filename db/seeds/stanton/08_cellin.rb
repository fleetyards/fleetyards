# frozen_string_literal: true

cellin = CelestialObject.find_or_create_by!(name: 'Cellin')
cellin.update!(store_image: Rails.root.join('db/seeds/images/cellin/cellin.jpg').open, hidden: false)

kareah = Station.find_or_initialize_by(name: 'Security Post Kareah')
kareah.update!(celestial_object: cellin, station_type: :station, location: 'Orbit', store_image: Rails.root.join('db/seeds/images/cellin/kareah.jpg').open, hidden: false)
kareah.docks.destroy_all
pad = 1
{ small: 6, medium: 1, large: 1 }.each do |ship_size, count|
  count.times do
    kareah.docks << Dock.new(
      name: "Ladingpad #{"%02d" % pad}",
      dock_type: :landingpad,
      ship_size: ship_size,
    )
    pad += 1
  end
end

gallete = Station.find_or_initialize_by(name: 'Gallete Family Farms')
gallete.update!(celestial_object: cellin, station_type: :outpost, location: 'cellin', hidden: true)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: gallete)
admin_office.update!(shop_type: :admin, hidden: true)

hickes = Station.find_or_initialize_by(name: 'Hickes Research Outpost')
hickes.update!(celestial_object: cellin, station_type: :outpost, location: 'cellin', store_image: Rails.root.join('db/seeds/images/cellin/hickes.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: hickes)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/cellin/hickes_admin.jpg').open, hidden: false)

terra_mills = Station.find_or_initialize_by(name: 'Terra Mills HydroFarm')
terra_mills.update!(celestial_object: cellin, station_type: :outpost, location: 'cellin', store_image: Rails.root.join('db/seeds/images/cellin/terra_mills.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: terra_mills)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/cellin/terra_mills_admin.jpg').open, hidden: false)

tram_n_myers = Station.find_or_initialize_by(name: 'Tram & Myers Mining')
tram_n_myers.update!(celestial_object: cellin, station_type: :outpost, location: 'cellin', hidden: true)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: tram_n_myers)
admin_office.update!(shop_type: :admin, hidden: true)

ashburn = Station.find_or_initialize_by(name: 'Ashburn Channel Aid Shelter')
ashburn.update!(celestial_object: cellin, station_type: :aid_shelter, location: 'cellin', hidden: true)

flanagan = Station.find_or_initialize_by(name: "Flanagan's Ravine Aid Shelter")
flanagan.update!(celestial_object: cellin, station_type: :aid_shelter, location: 'cellin', hidden: true)

julep = Station.find_or_initialize_by(name: 'Julep Ravine Aid Shelter')
julep.update!(celestial_object: cellin, station_type: :aid_shelter, location: 'cellin', hidden: true)

mogote = Station.find_or_initialize_by(name: 'Mogote Shelter')
mogote.update!(celestial_object: cellin, station_type: :aid_shelter, location: 'cellin', hidden: true)
