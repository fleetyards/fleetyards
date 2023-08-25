# frozen_string_literal: true

# TODO: take new image of Daymar

daymar = CelestialObject.find_or_create_by!(name: "Daymar")
daymar.update!(remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/daymar.jpg", hidden: false)

covalex_shipping = Station.find_or_initialize_by(name: "Covalex Hub Gundo")
covalex_shipping.update!(
  celestial_object: daymar,
  station_type: :station,
  size: :small,
  habitable: false,
  location: nil,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/covalex.jpg",
  hidden: false
)

shubin = Station.find_or_initialize_by(name: "Shubin Mining Facility SCD-1")
shubin.update!(
  celestial_object: daymar,
  station_type: :outpost,
  classification: :mining,
  size: :small,
  location: nil,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/shubin.jpg",
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: shubin)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/shubin_admin.jpg",
  buying: true,
  selling: true,
  hidden: false
)

shubin.docks.destroy_all
{small: [1, 2]}.each do |ship_size, pads|
  pads.each do |pad|
    shubin.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size
    )
  end
end
{medium: [1], large: [2]}.each do |ship_size, pads|
  pads.each do |pad|
    shubin.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size
    )
  end
end

arccorp = Station.find_or_initialize_by(name: "ArcCorp Mining Area 141")
arccorp.update!(
  celestial_object: daymar,
  station_type: :outpost,
  classification: :mining,
  size: :small,
  location: nil,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/arccorp.jpg",
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: arccorp)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/arccorp_admin.jpg",
  buying: true,
  selling: true,
  hidden: false
)

arccorp.docks.destroy_all
{small: [1, 2]}.each do |ship_size, pads|
  pads.each do |pad|
    arccorp.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size
    )
  end
end
{medium: [1]}.each do |ship_size, pads|
  pads.each do |pad|
    arccorp.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size
    )
  end
end

kudre_ore = Station.find_or_initialize_by(name: "Kudre Ore")
kudre_ore.update!(
  celestial_object: daymar,
  station_type: :outpost,
  classification: :mining,
  size: :small,
  location: nil,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/kudre.jpg",
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: kudre_ore)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/kudre_admin.jpg",
  buying: true,
  selling: true,
  hidden: false
)

bountiful_harvest = Station.find_or_initialize_by(name: "Bountiful Harvest Hydroponics")
bountiful_harvest.update!(
  celestial_object: daymar,
  station_type: :outpost,
  classification: :farming,
  size: :small,
  location: nil,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/bountiful.jpg",
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: bountiful_harvest)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/bountiful_admin.jpg",
  buying: true,
  selling: true,
  hidden: false
)

eager_flats = Station.find_or_initialize_by(name: "Eager Flats Aid Shelter")
eager_flats.update!(celestial_object: daymar, station_type: :aid_shelter, location: nil, remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/eager.jpg", hidden: false)

wolf_point = Station.find_or_initialize_by(name: "Wolf Point Aid Shelter")
wolf_point.update!(celestial_object: daymar, station_type: :aid_shelter, location: nil, remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/wolfpoint.jpg", hidden: false)

tamdon_plains = Station.find_or_initialize_by(name: "Tamdon Plains Aid Shelter")
tamdon_plains.update!(celestial_object: daymar, station_type: :aid_shelter, location: nil, remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/tamdon.jpg", hidden: false)

dunlow_ridge = Station.find_or_initialize_by(name: "Dunlow Ridge Aid Shelter")
dunlow_ridge.update!(celestial_object: daymar, station_type: :aid_shelter, location: nil, remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/dunlow_ridge.jpg", hidden: false)

nuen = Station.find_or_initialize_by(name: "Nuen Waste Management")
nuen.update!(
  celestial_object: daymar,
  station_type: :aid_shelter,
  classification: :drug_lab,
  size: :small,
  location: nil,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/nuen.jpg',
  hidden: true
)
admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: nuen)
admin_office.update!(
  shop_type: :admin,
  selling: true,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/nuen_admin.jpg',
  hidden: true
)

brios = Station.find_or_initialize_by(name: "Brio's Breaker Yard")
brios.update!(
  celestial_object: daymar,
  station_type: :outpost,
  classification: :salvaging,
  size: :small,
  location: nil,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/brios.jpg',
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: brios)
admin_office.update!(
  shop_type: :admin,
  selling: true,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/daymar/brios_admin.jpg',
  hidden: false
)
