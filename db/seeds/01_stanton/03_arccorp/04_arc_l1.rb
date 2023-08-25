# frozen_string_literal: true

arccorp = CelestialObject.find_or_create_by!(name: "ArcCorp")

hidden = false

arc_l1 = Station.find_or_initialize_by(name: "ARC-L1 Wide Forest Station")
arc_l1.update!(
  celestial_object: arccorp,
  station_type: :station,
  classification: :rest_stop,
  size: :large,
  location: "ARC-L1",
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/arc-l1/arc-l1.jpg",
  refinery: true,
  hidden: hidden
)

arc_l1.docks.destroy_all
{small: [1, 3], large: [2, 4]}.each do |ship_size, pads|
  pads.each do |pad|
    arc_l1.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size
    )
  end
end
{large: [1, 2, 3, 4]}.each do |ship_size, hangars|
  hangars.each do |hangar|
    arc_l1.docks << Dock.new(
      name: ("%02d" % hangar),
      dock_type: :hangar,
      ship_size: ship_size
    )
  end
end

arc_l1.habitations.destroy_all
%w[1 2 3 4 5].each do |level|
  pad = 1
  {container: 11}.each do |hab_size, count|
    count.times do
      arc_l1.habitations << Habitation.new(
        name: "Hab #{level}#{"%02d" % pad}",
        habitation_name: "EZ Hab",
        habitation_type: hab_size
      )
      pad += 1
    end
  end
end

admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: arc_l1)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/arc-l1/admin.jpg",
  buying: true,
  selling: true,
  hidden: hidden
)

live_fire_weapons = Shop.find_or_initialize_by(name: "Live Fire Weapons", station: arc_l1)
live_fire_weapons.update!(
  shop_type: :weapons,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/arc-l1/weapons.jpg",
  selling: true,
  hidden: hidden
)

casaba = Shop.find_or_initialize_by(name: "Casaba Outlet", station: arc_l1)
casaba.update!(
  shop_type: :clothing,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/arc-l1/casaba.jpg",
  selling: true,
  hidden: hidden
)

platinum_bay = Shop.find_or_initialize_by(name: "Platinum Bay", station: arc_l1)
platinum_bay.update!(
  shop_type: :components,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/arccorp/arc-l1/platinum.jpg",
  selling: true,
  hidden: hidden
)
