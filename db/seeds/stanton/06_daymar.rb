# frozen_string_literal: true

crusader = Planet.find_by!(name: 'Crusader')

daymar = Planet.find_or_initialize_by(name: 'Daymar')
daymar.update!(planet: crusader, store_image: Rails.root.join('db/seeds/images/daymar/daymar.jpg').open)

corvolex_shipping = Station.find_or_initialize_by(name: 'Covalex Hub Gundo')
corvolex_shipping.update!(planet: daymar, station_type: 'cargo-station', location: 'Orbit')

shubin = Station.find_or_initialize_by(name: 'Shubin Mining Facility SCD-1')
shubin.update!(planet: daymar, station_type: :outpost, location: 'Daymar')
admin_office = Shop.find_or_create_by(name: 'Admin Office', station: shubin)
admin_office.update!(shop_type: :admin)

arccorp = Station.find_or_initialize_by(name: 'ArcCorp Mining Area 141')
arccorp.update!(planet: daymar, station_type: :outpost, location: 'Daymar')
admin_office = Shop.find_or_create_by(name: 'Admin Office', station: arccorp)
admin_office.update!(shop_type: :admin)

kudre_ore = Station.find_or_initialize_by(name: 'Kudre Ore')
kudre_ore.update!(planet: daymar, station_type: :outpost, location: 'Daymar')
admin_office = Shop.find_or_create_by(name: 'Admin Office', station: kudre_ore)
admin_office.update!(shop_type: :admin)

bountiful_harvest = Station.find_or_initialize_by(name: 'Bountiful Harvest Hydroponics')
bountiful_harvest.update!(planet: daymar, station_type: :outpost, location: 'Daymar')
admin_office = Shop.find_or_create_by(name: 'Admin Office', station: bountiful_harvest)
admin_office.update!(shop_type: :admin)

eager_flats = Station.find_or_initialize_by(name: 'Eager Flats Aid Shelter')
eager_flats.update!(planet: daymar, station_type: :aid_shelter, location: 'Daymar')

wolf_point = Station.find_or_initialize_by(name: 'Wolf Point Aid Shelter')
wolf_point.update!(planet: daymar, station_type: :aid_shelter, location: 'Daymar')

tamdon_plains = Station.find_or_initialize_by(name: 'Tamdon Plains Aid Shelter')
tamdon_plains.update!(planet: daymar, station_type: :aid_shelter, location: 'Daymar')

dunlow_ridge = Station.find_or_initialize_by(name: 'Dunlow Ridge Aid Shelter')
dunlow_ridge.update!(planet: daymar, station_type: :aid_shelter, location: 'Daymar')
