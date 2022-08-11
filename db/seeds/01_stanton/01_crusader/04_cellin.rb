# frozen_string_literal: true

# TODO: take new image of Cellin

cellin = CelestialObject.find_or_create_by!(name: 'Cellin')
cellin.update!(remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cellin/cellin.jpg', hidden: false)

kareah = Station.find_or_initialize_by(name: 'Security Post Kareah')
kareah.update!(
  celestial_object: cellin,
  station_type: :station,
  classification: :security,
  location: nil,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cellin/kareah.jpg',
  hidden: false
)

kareah.docks.destroy_all
{ small: [2, 3, 4, 6, 7, 8],  medium: [1, 5] }.each do |ship_size, pads|
  pads.each do |pad|
    kareah.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end

gallete = Station.find_or_initialize_by(name: 'Gallete Family Farms')
gallete.update!(
  celestial_object: cellin,
  station_type: :outpost,
  classification: :farming,
  location: nil,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cellin/gallete.jpg',
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: gallete)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cellin/gallete_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)

hickes = Station.find_or_initialize_by(name: 'Hickes Research Outpost')
hickes.update!(
  celestial_object: cellin,
  station_type: :outpost,
  classification: :science,
  location: nil,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cellin/hickes.jpg',
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: hickes)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cellin/hickes_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)

hickes.docks.destroy_all
{ small: [1, 2] }.each do |ship_size, pads|
  pads.each do |pad|
    hickes.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
  end
end
{ small: [1],  medium: [2] }.each do |ship_size, pads|
  pads.each do |pad|
    hickes.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end

terra_mills = Station.find_or_initialize_by(name: 'Terra Mills HydroFarm')
terra_mills.update!(
  celestial_object: cellin,
  station_type: :outpost,
  classification: :farming,
  location: nil,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cellin/terra_mills.jpg',
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: terra_mills)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cellin/terra_mills_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)

terra_mills.docks.destroy_all
{ small: [1, 2] }.each do |ship_size, pads|
  pads.each do |pad|
    terra_mills.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
  end
end
{ small: [1],  medium: [2] }.each do |ship_size, pads|
  pads.each do |pad|
    terra_mills.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end

tram_n_myers = Station.find_or_initialize_by(name: 'Tram & Myers Mining')
tram_n_myers.update!(
  celestial_object: cellin,
  station_type: :outpost,
  classification: :mining,
  location: nil,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cellin/tram_n_myers.jpg',
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: tram_n_myers)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cellin/tram_n_myers_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)

ashburn = Station.find_or_initialize_by(name: 'Ashburn Channel Aid Shelter')
ashburn.update!(
  celestial_object: cellin,
  station_type: :aid_shelter,
  location: nil,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cellin/ashburn.jpg',
  hidden: false
)

flanagan = Station.find_or_initialize_by(name: "Flanagan's Ravine Aid Shelter")
flanagan.update!(
  celestial_object: cellin,
  station_type: :aid_shelter,
  location: nil,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cellin/flanagan.jpg',
  hidden: false
)

julep = Station.find_or_initialize_by(name: 'Julep Ravine Aid Shelter')
julep.update!(
  celestial_object: cellin,
  station_type: :aid_shelter,
  location: nil,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cellin/julep.jpg',
  hidden: false
)

mogote = Station.find_or_initialize_by(name: 'Mogote Shelter')
mogote.update!(
  celestial_object: cellin,
  station_type: :aid_shelter,
  location: nil,
  remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cellin/mogote.jpg',
  hidden: false
)

private_property = Station.find_or_initialize_by(name: 'PRIVATE PROPERTY')
private_property.update!(
  celestial_object: cellin,
  station_type: :aid_shelter,
  classification: :drug_lab,
  location: nil,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cellin/private_property.jpg',
  hidden: true
)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: private_property)
admin_office.update!(
  shop_type: :admin,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cellin/private_property_admin.jpg',
  buying: true,
  selling: true,
  hidden: true
)
