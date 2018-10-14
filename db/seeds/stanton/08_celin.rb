# frozen_string_literal: true

crusader = Planet.find_by!(name: 'Crusader')

celin = Planet.find_or_initialize_by(name: 'Celin')
celin.update!(planet: crusader, store_image: Rails.root.join('db/seeds/images/celin/celin.jpg').open)

kareah = Station.find_or_initialize_by(name: 'Kareah')
kareah.update!(planet: celin, station_type: :station, location: 'Orbit')

gallete = Station.find_or_initialize_by(name: 'Gallete Family Farms')
gallete.update!(planet: celin, station_type: :outpost, location: 'Celin')
admin_office = Shop.find_or_create_by(name: 'Admin Office', station: gallete)
admin_office.update!(shop_type: :admin)

hickes = Station.find_or_initialize_by(name: 'Hickes Research Outpost')
hickes.update!(planet: celin, station_type: :outpost, location: 'Celin')
admin_office = Shop.find_or_create_by(name: 'Admin Office', station: hickes)
admin_office.update!(shop_type: :admin)

terra_mills = Station.find_or_initialize_by(name: 'Terra Mills HydroFarm')
terra_mills.update!(planet: celin, station_type: :outpost, location: 'Celin')
admin_office = Shop.find_or_create_by(name: 'Admin Office', station: terra_mills)
admin_office.update!(shop_type: :admin)

tram_n_myers = Station.find_or_initialize_by(name: 'Tram & Myers Mining')
tram_n_myers.update!(planet: celin, station_type: :outpost, location: 'Celin')
admin_office = Shop.find_or_create_by(name: 'Admin Office', station: tram_n_myers)
admin_office.update!(shop_type: :admin)

ashburn = Station.find_or_initialize_by(name: 'Ashburn Channel Aid Shelter')
ashburn.update!(planet: celin, station_type: :aid_shelter, location: 'Celin')

flanagan = Station.find_or_initialize_by(name: "Flanagan's Ravine Aid Shelter")
flanagan.update!(planet: celin, station_type: :aid_shelter, location: 'Celin')

julep = Station.find_or_initialize_by(name: 'Julep Ravine Aid Shelter')
julep.update!(planet: celin, station_type: :aid_shelter, location: 'Celin')

mogote = Station.find_or_initialize_by(name: 'Mogote Shelter')
mogote.update!(planet: celin, station_type: :aid_shelter, location: 'Celin')
