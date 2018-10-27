# frozen_string_literal: true

cellin = CelestialObject.find_or_create_by!(name: 'Cellin')
cellin.update!(store_image: Rails.root.join('db/seeds/images/cellin/cellin.jpg').open, hidden: false)

kareah = Station.find_or_initialize_by(name: 'Security Post Kareah')
kareah.update!(celestial_object: cellin, station_type: :station, location: 'Orbit')

gallete = Station.find_or_initialize_by(name: 'Gallete Family Farms')
gallete.update!(celestial_object: cellin, station_type: :outpost, location: 'cellin')
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: gallete)
admin_office.update!(shop_type: :admin)

hickes = Station.find_or_initialize_by(name: 'Hickes Research Outpost')
hickes.update!(celestial_object: cellin, station_type: :outpost, location: 'cellin')
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: hickes)
admin_office.update!(shop_type: :admin)

terra_mills = Station.find_or_initialize_by(name: 'Terra Mills HydroFarm')
terra_mills.update!(celestial_object: cellin, station_type: :outpost, location: 'cellin')
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: terra_mills)
admin_office.update!(shop_type: :admin)

tram_n_myers = Station.find_or_initialize_by(name: 'Tram & Myers Mining')
tram_n_myers.update!(celestial_object: cellin, station_type: :outpost, location: 'cellin')
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: tram_n_myers)
admin_office.update!(shop_type: :admin)

ashburn = Station.find_or_initialize_by(name: 'Ashburn Channel Aid Shelter')
ashburn.update!(celestial_object: cellin, station_type: :aid_shelter, location: 'cellin')

flanagan = Station.find_or_initialize_by(name: "Flanagan's Ravine Aid Shelter")
flanagan.update!(celestial_object: cellin, station_type: :aid_shelter, location: 'cellin')

julep = Station.find_or_initialize_by(name: 'Julep Ravine Aid Shelter')
julep.update!(celestial_object: cellin, station_type: :aid_shelter, location: 'cellin')

mogote = Station.find_or_initialize_by(name: 'Mogote Shelter')
mogote.update!(celestial_object: cellin, station_type: :aid_shelter, location: 'cellin')
