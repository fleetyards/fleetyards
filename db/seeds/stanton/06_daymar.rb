# frozen_string_literal: true

daymar = CelestialObject.find_or_create_by!(name: 'Daymar')
daymar.update!(store_image: Rails.root.join('db/seeds/images/daymar/daymar.jpg').open, hidden: false)

corvolex_shipping = Station.find_or_initialize_by(name: 'Covalex Hub Gundo')
corvolex_shipping.update!(celestial_object: daymar, station_type: 'cargo-station', location: 'Orbit', hidden: true)

shubin = Station.find_or_initialize_by(name: 'Shubin Mining Facility SCD-1')
shubin.update!(celestial_object: daymar, station_type: :outpost, location: 'Daymar', hidden: true)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: shubin)
admin_office.update!(shop_type: :admin, hidden: true)

arccorp = Station.find_or_initialize_by(name: 'ArcCorp Mining Area 141')
arccorp.update!(celestial_object: daymar, station_type: :outpost, location: 'Daymar', hidden: true)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: arccorp)
admin_office.update!(shop_type: :admin, hidden: true)

kudre_ore = Station.find_or_initialize_by(name: 'Kudre Ore')
kudre_ore.update!(celestial_object: daymar, station_type: :outpost, location: 'Daymar', hidden: true)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: kudre_ore)
admin_office.update!(shop_type: :admin)

bountiful_harvest = Station.find_or_initialize_by(name: 'Bountiful Harvest Hydroponics')
bountiful_harvest.update!(celestial_object: daymar, station_type: :outpost, location: 'Daymar', hidden: true)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: bountiful_harvest)
admin_office.update!(shop_type: :admin, hidden: true)

eager_flats = Station.find_or_initialize_by(name: 'Eager Flats Aid Shelter')
eager_flats.update!(celestial_object: daymar, station_type: :aid_shelter, location: 'Daymar', hidden: true)

wolf_point = Station.find_or_initialize_by(name: 'Wolf Point Aid Shelter')
wolf_point.update!(celestial_object: daymar, station_type: :aid_shelter, location: 'Daymar', hidden: true)

tamdon_plains = Station.find_or_initialize_by(name: 'Tamdon Plains Aid Shelter')
tamdon_plains.update!(celestial_object: daymar, station_type: :aid_shelter, location: 'Daymar', hidden: true)

dunlow_ridge = Station.find_or_initialize_by(name: 'Dunlow Ridge Aid Shelter')
dunlow_ridge.update!(celestial_object: daymar, station_type: :aid_shelter, location: 'Daymar', hidden: true)
