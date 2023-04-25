# frozen_string_literal: true

yela = CelestialObject.find_or_create_by!(name: "Yela")
yela.update!(remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/yela.jpg", hidden: false)

grimhex = Station.find_or_initialize_by(name: "GrimHEX")
grimhex.update!(
  celestial_object: yela,
  station_type: :asteroid_station,
  classification: :trading,
  location: nil,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/grimhex.jpg",
  hidden: false
)

grimhex.docks.destroy_all
{extra_small: [3, 4, 5], small: [1, 6], medium: [2]}.each do |ship_size, pads|
  pads.each do |pad|
    grimhex.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size
    )
  end
end

grimhex.habitations.destroy_all
%w[A B C D].each do |wing|
  pad = 1
  {container: 8}.each do |_ship_size, count|
    count.times do
      grimhex.habitations << Habitation.new(
        name: ("%02d" % pad),
        habitation_name: "Wing #{wing}",
        habitation_type: :container
      )
      pad += 1
    end
  end
end

admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: grimhex)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/grimhex_admin.jpg",
  buying: true,
  selling: true,
  hidden: false
)
dumpers_depot = Shop.find_or_initialize_by(name: "Dumper's Depot", station: grimhex)
dumpers_depot.update!(
  shop_type: :components,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/grimhex_dumpers.jpg",
  selling: true,
  hidden: false
)
ruto = Shop.find_or_initialize_by(name: "Ruto's Room", station: grimhex)
ruto.update!(
  shop_type: :blackmarket,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/rutos.jpg',
  selling: true,
  hidden: false
)
skutters = Shop.find_or_initialize_by(name: "Skutters", station: grimhex)
skutters.update!(
  shop_type: :armor_and_weapons,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/skutters.jpg",
  selling: true,
  hidden: false
)
kc_trending = Shop.find_or_initialize_by(name: "KC Trending", station: grimhex)
kc_trending.update!(
  shop_type: :clothing,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/kc_trending.jpg",
  selling: true,
  hidden: false
)
old_38 = Shop.find_or_initialize_by(name: "Old '38", station: grimhex)
old_38.update!(
  shop_type: :bar,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/old_38.jpg",
  hidden: false
)

deakins_research_outpost = Station.find_or_initialize_by(name: "Deakins Research Outpost")
deakins_research_outpost.update!(
  celestial_object: yela,
  station_type: :outpost,
  classification: :science,
  location: nil,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/deakins_research_outpost.jpg",
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: deakins_research_outpost)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/deakins_research_outpost_admin.jpg",
  buying: true,
  selling: true,
  hidden: false
)

deakins_research_outpost.docks.destroy_all
{small: [1, 2]}.each do |ship_size, pads|
  pads.each do |pad|
    deakins_research_outpost.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size
    )
  end
end
{small: [1], medium: [2]}.each do |ship_size, pads|
  pads.each do |pad|
    deakins_research_outpost.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size
    )
  end
end

benson_mining_outpost = Station.find_or_initialize_by(name: "Benson Mining Outpost")
benson_mining_outpost.update!(
  celestial_object: yela,
  station_type: :outpost,
  classification: :mining,
  location: nil,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/benson_mining.jpg",
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: benson_mining_outpost)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/benson_mining_admin.jpg",
  buying: true,
  selling: true,
  hidden: false
)

arc_corp_mining_area_157 = Station.find_or_initialize_by(name: "ArcCorp Mining Area 157")
arc_corp_mining_area_157.update!(
  celestial_object: yela,
  station_type: :outpost,
  classification: :mining,
  location: nil,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/arccorp.jpg",
  hidden: false
)
admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: arc_corp_mining_area_157)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/arccorp_admin.jpg",
  buying: true,
  selling: true,
  hidden: false
)

arc_corp_mining_area_157.docks.destroy_all
{small: [1, 2]}.each do |ship_size, pads|
  pads.each do |pad|
    arc_corp_mining_area_157.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size
    )
  end
end
{medium: [1]}.each do |ship_size, pads|
  pads.each do |pad|
    arc_corp_mining_area_157.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size
    )
  end
end

nakamura_valley_aid_shelter = Station.find_or_initialize_by(name: "Nakamura Valley Aid Shelter")
nakamura_valley_aid_shelter.update!(celestial_object: yela, station_type: :aid_shelter, location: nil, remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/nakamura_valley.jpg", hidden: false)

kosso_basin_aid_shelter = Station.find_or_initialize_by(name: "Kosso Basin Aid Shelter")
kosso_basin_aid_shelter.update!(celestial_object: yela, station_type: :aid_shelter, location: nil, remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/kosso_basin.jpg", hidden: false)

aston_ridge_aid_shelter = Station.find_or_initialize_by(name: "Aston Ridge Aid Shelter")
aston_ridge_aid_shelter.update!(celestial_object: yela, station_type: :aid_shelter, location: nil, remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/aston_ridge.jpg", hidden: false)

talarine_divide_aid_shelter = Station.find_or_initialize_by(name: "Talarine Divide Aid Shelter")
talarine_divide_aid_shelter.update!(celestial_object: yela, station_type: :aid_shelter, location: nil, remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/talarine_divide.jpg", hidden: false)

jump_town = Station.find_or_initialize_by(name: "Jump Town")
jump_town.update!(
  celestial_object: yela,
  station_type: :aid_shelter,
  classification: :drug_lab,
  location: nil,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/jump_town.jpg',
  hidden: true
)
admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: jump_town)
admin_office.update!(
  shop_type: :admin,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/jump_town_admin.jpg',
  selling: true,
  hidden: true
)

nt_999 = Station.find_or_initialize_by(name: "NT-999-XX")
nt_999.update!(
  celestial_object: yela,
  station_type: :aid_shelter,
  classification: :drug_lab,
  location: nil,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/nt_999.jpg',
  hidden: true
)
admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: nt_999)
admin_office.update!(
  shop_type: :admin,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/yela/nt_999_admin.jpg',
  selling: true,
  hidden: true
)
