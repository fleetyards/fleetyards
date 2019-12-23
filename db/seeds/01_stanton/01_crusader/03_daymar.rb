# frozen_string_literal: true

# TODO: take new image of Daymar

daymar = CelestialObject.find_or_create_by!(name: 'Daymar')
daymar.update!(store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/daymar.jpg').open, hidden: false)

corvolex_shipping = Station.find_or_initialize_by(name: 'Covalex Hub Gundo')
corvolex_shipping.update!(celestial_object: daymar, station_type: 'cargo-station', location: nil, store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/covalex.jpg').open, hidden: false)

shubin = Station.find_or_initialize_by(name: 'Shubin Mining Facility SCD-1')
shubin.update!(celestial_object: daymar, station_type: :outpost, location: nil, store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/shubin.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: shubin)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/shubin_admin.jpg').open, hidden: false)

shubin.docks.destroy_all
{ small: [1, 2] }.each do |ship_size, pads|
  pads.each do |pad|
    shubin.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
  end
end
{ small: [1],  medium: [2] }.each do |ship_size, pads|
  pads.each do |pad|
    shubin.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end

arccorp = Station.find_or_initialize_by(name: 'ArcCorp Mining Area 141')
arccorp.update!(celestial_object: daymar, station_type: :outpost, location: nil, store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/arccorp.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: arccorp)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/arccorp_admin.jpg').open, hidden: false)

arccorp.docks.destroy_all
{ small: [1, 2] }.each do |ship_size, pads|
  pads.each do |pad|
    arccorp.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
  end
end
{ small: [1],  medium: [2] }.each do |ship_size, pads|
  pads.each do |pad|
    arccorp.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end

kudre_ore = Station.find_or_initialize_by(name: 'Kudre Ore')
kudre_ore.update!(celestial_object: daymar, station_type: :outpost, location: nil, store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/kudre.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: kudre_ore)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/kudre_admin.jpg').open, hidden: false)

bountiful_harvest = Station.find_or_initialize_by(name: 'Bountiful Harvest Hydroponics')
bountiful_harvest.update!(celestial_object: daymar, station_type: :outpost, location: nil, store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/bountiful.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: bountiful_harvest)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/bountiful_admin.jpg').open, hidden: false)

eager_flats = Station.find_or_initialize_by(name: 'Eager Flats Aid Shelter')
eager_flats.update!(celestial_object: daymar, station_type: :aid_shelter, location: nil, store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/eager.jpg').open, hidden: false)

wolf_point = Station.find_or_initialize_by(name: 'Wolf Point Aid Shelter')
wolf_point.update!(celestial_object: daymar, station_type: :aid_shelter, location: nil, store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/wolfpoint.jpg').open, hidden: false)

tamdon_plains = Station.find_or_initialize_by(name: 'Tamdon Plains Aid Shelter')
tamdon_plains.update!(celestial_object: daymar, station_type: :aid_shelter, location: nil, store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/tamdon.jpg').open, hidden: false)

dunlow_ridge = Station.find_or_initialize_by(name: 'Dunlow Ridge Aid Shelter')
dunlow_ridge.update!(celestial_object: daymar, station_type: :aid_shelter, location: nil, store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/dunlow_ridge.jpg').open, hidden: false)

nuen = Station.find_or_initialize_by(name: 'Nuen Waste Management')
nuen.update!(
  celestial_object: daymar,
  station_type: :drug_lab,
  location: nil,
  # store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/nuen.jpg').open,
  hidden: true
)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: nuen)
admin_office.update!(
  shop_type: :admin,
  # store_image: Rails.root.join('db/seeds/images/stanton/crusader/daymar/nuen_admin.jpg').open,
  hidden: true
)
