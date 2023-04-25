# frozen_string_literal: true

microtech = CelestialObject.find_or_create_by!(name: "microTech")

hidden = false

mic_l1 = Station.find_or_initialize_by(name: "MIC-L1 Shallow Frontier Station")
mic_l1.update!(
  celestial_object: microtech,
  station_type: :station,
  classification: :rest_stop,
  location: "MIC-L1",
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/microtech/mic-l1/mic-l1.jpg",
  refinery: true,
  hidden: hidden
)

mic_l1.docks.destroy_all
{small: [1, 3], large: [2, 4]}.each do |ship_size, pads|
  pads.each do |pad|
    mic_l1.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size
    )
  end
end
{large: [1, 2]}.each do |ship_size, hangars|
  hangars.each do |hangar|
    mic_l1.docks << Dock.new(
      name: ("%02d" % hangar),
      dock_type: :hangar,
      ship_size: ship_size
    )
  end
end

mic_l1.habitations.destroy_all
%w[1 2 3 4 5].each do |level|
  pad = 1
  {container: 11}.each do |hab_size, count|
    count.times do
      mic_l1.habitations << Habitation.new(
        name: "Hab #{level}#{"%02d" % pad}",
        habitation_name: "EZ Hab",
        habitation_type: hab_size
      )
      pad += 1
    end
  end
end

admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: mic_l1)
admin_office.update!(
  shop_type: :admin,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/microtech/mic-l1/admin.jpg",
  buying: true,
  selling: true,
  hidden: hidden
)

bulwark_armor = Shop.find_or_initialize_by(name: "Bulwark Armor", station: mic_l1)
bulwark_armor.update!(
  shop_type: :armor,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/microtech/mic-l1/armor.jpg",
  selling: true,
  hidden: hidden
)

casaba = Shop.find_or_initialize_by(name: "Casaba Outlet", station: mic_l1)
casaba.update!(
  shop_type: :clothing,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/microtech/mic-l1/casaba.jpg",
  selling: true,
  hidden: hidden
)

platinum_bay = Shop.find_or_initialize_by(name: "Platinum Bay", station: mic_l1)
platinum_bay.update!(
  shop_type: :components,
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/microtech/mic-l1/platinum_bay.jpg",
  selling: true,
  hidden: hidden
)
