# frozen_string_literal: true

arccorp = CelestialObject.find_or_create_by!(name: "ArcCorp")

hidden = false

baijini = Station.find_or_initialize_by(name: "Baijini Point")
baijini.update!(
  celestial_object: arccorp,
  station_type: :station,
  classification: :trading,
  location: nil,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/baijini/baijini.jpg",
  cargo_hub: true,
  hidden: hidden
)

baijini.docks.destroy_all
{small: [1, 4], large: [2, 3]}.each do |ship_size, pads|
  pads.each do |pad|
    baijini.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size
    )
  end
end
{large: [1, 2, 3, 4]}.each do |ship_size, hangars|
  hangars.each do |hangar|
    baijini.docks << Dock.new(
      name: ("%02d" % hangar),
      dock_type: :hangar,
      ship_size: ship_size
    )
  end
end

baijini.habitations.destroy_all
%w[1 2 3 4 5].each do |level|
  pad = 1
  {container: 10}.each do |hab_size, count|
    count.times do
      baijini.habitations << Habitation.new(
        name: "Level #{"%02d" % level} Hab #{"%02d" % pad}",
        habitation_name: "EZ Hab",
        habitation_type: hab_size
      )
      pad += 1
    end
  end
end

admin = Shop.find_or_initialize_by(name: "Admin Office", station: baijini)
admin.update!(
  shop_type: :admin,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/baijini/admin.jpg",
  buying: true,
  selling: true,
  hidden: hidden
)

bulwark_armor = Shop.find_or_initialize_by(name: "Bulwark Armor", station: baijini)
bulwark_armor.update!(
  shop_type: :armor,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/baijini/armor.jpg",
  selling: true,
  hidden: hidden
)

platinum_bay = Shop.find_or_initialize_by(name: "Platinum Bay", station: baijini)
platinum_bay.update!(
  shop_type: :components,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/baijini/platinum_bay.jpg",
  selling: true,
  hidden: hidden
)

casaba = Shop.find_or_initialize_by(name: "Casaba Outlet", station: baijini)
casaba.update!(
  shop_type: :clothing,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/baijini/casaba.jpg",
  selling: true,
  hidden: hidden
)

traveler_rentals = Shop.find_or_initialize_by(name: "Traveler Rentals", station: baijini)
traveler_rentals.update!(
  shop_type: :rental,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/traveler-rentals.jpg',
  rental: true,
  hidden: hidden
)
