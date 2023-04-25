# frozen_string_literal: true

calliope = CelestialObject.find_or_create_by!(name: "Calliope")
calliope.update!(remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/microtech/calliope/calliope.jpg", hidden: false)

rayari_anvik = Station.find_or_initialize_by(name: "Rayari Anvik Research Outpost")
rayari_anvik.update!(
  celestial_object: calliope,
  station_type: :outpost,
  classification: :science,
  location: "Calliope",
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/stanhope.jpg',
  hidden: false
)

admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: rayari_anvik)
admin_office.update!(
  shop_type: :admin,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/stanhope_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)

rayari_anvik.docks.destroy_all
pad = 1
{small: 2}.each do |ship_size, count|
  count.times do
    rayari_anvik.docks << Dock.new(
      name: "Vehiclepad #{"%02d" % pad}",
      dock_type: :vehiclepad,
      ship_size: ship_size
    )
    pad += 1
  end
end
pad = 1
{medium: 1, large: 1}.each do |ship_size, count|
  count.times do |_index|
    rayari_anvik.docks << Dock.new(
      name: "Ladingpad #{"%02d" % pad}",
      dock_type: :landingpad,
      ship_size: ship_size
    )
    pad += 1
  end
end

rayari_kaltag = Station.find_or_initialize_by(name: "Rayari Kaltag Research Outpost")
rayari_kaltag.update!(
  celestial_object: calliope,
  station_type: :outpost,
  classification: :science,
  location: "Calliope",
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/stanhope.jpg',
  hidden: false
)

admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: rayari_kaltag)
admin_office.update!(
  shop_type: :admin,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/stanhope_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)

rayari_kaltag.docks.destroy_all
pad = 1
{small: 2}.each do |ship_size, count|
  count.times do
    rayari_kaltag.docks << Dock.new(
      name: "Vehiclepad #{"%02d" % pad}",
      dock_type: :vehiclepad,
      ship_size: ship_size
    )
    pad += 1
  end
end
pad = 1
{medium: 1, large: 1}.each do |ship_size, count|
  count.times do |_index|
    rayari_kaltag.docks << Dock.new(
      name: "Ladingpad #{"%02d" % pad}",
      dock_type: :landingpad,
      ship_size: ship_size
    )
    pad += 1
  end
end

shubin_smca_6 = Station.find_or_initialize_by(name: "Shubin Mining Facility SMCa-6")
shubin_smca_6.update!(
  celestial_object: calliope,
  station_type: :outpost,
  classification: :mining,
  location: "Calliope",
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/stanhope.jpg',
  hidden: false
)

admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: shubin_smca_6)
admin_office.update!(
  shop_type: :admin,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/stanhope_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)

shubin_smca_6.docks.destroy_all
pad = 1
{small: 2}.each do |ship_size, count|
  count.times do
    shubin_smca_6.docks << Dock.new(
      name: "Vehiclepad #{"%02d" % pad}",
      dock_type: :vehiclepad,
      ship_size: ship_size
    )
    pad += 1
  end
end
pad = 1
{medium: 1, large: 1}.each do |ship_size, count|
  count.times do |_index|
    shubin_smca_6.docks << Dock.new(
      name: "Ladingpad #{"%02d" % pad}",
      dock_type: :landingpad,
      ship_size: ship_size
    )
    pad += 1
  end
end

shubin_smca_8 = Station.find_or_initialize_by(name: "Shubin Mining Facility SMCa-8")
shubin_smca_8.update!(
  celestial_object: calliope,
  station_type: :outpost,
  classification: :mining,
  location: "Calliope",
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/stanhope.jpg',
  hidden: false
)

admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: shubin_smca_8)
admin_office.update!(
  shop_type: :admin,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/stanhope_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)

shubin_smca_8.docks.destroy_all
pad = 1
{small: 2}.each do |ship_size, count|
  count.times do
    shubin_smca_8.docks << Dock.new(
      name: "Vehiclepad #{"%02d" % pad}",
      dock_type: :vehiclepad,
      ship_size: ship_size
    )
    pad += 1
  end
end
pad = 1
{medium: 1, large: 1}.each do |ship_size, count|
  count.times do |_index|
    shubin_smca_8.docks << Dock.new(
      name: "Ladingpad #{"%02d" % pad}",
      dock_type: :landingpad,
      ship_size: ship_size
    )
    pad += 1
  end
end

ravens = Station.find_or_initialize_by(name: "Raven's Roost")
ravens.update!(
  celestial_object: calliope,
  station_type: :outpost,
  classification: :drug_lab,
  location: nil,
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: ravens)
admin_office.update!(
  shop_type: :admin,
  selling: true,
  hidden: false
)
