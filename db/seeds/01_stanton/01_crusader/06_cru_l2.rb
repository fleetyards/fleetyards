# frozen_string_literal: true

crusader = CelestialObject.find_or_create_by!(name: 'Crusader')

hidden = true # currently not present 3.8.0

cru_l2 = Station.find_or_initialize_by(name: 'Rest & Relax (CRU-L2)')
cru_l2.update!(
  celestial_object: crusader,
  station_type: :station,
  classification: :rest_stop,
  location: 'CRU-L2',
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cru-l2/cru-l2.jpg',
  hidden: hidden
)

# cru_l2.docks.destroy_all
# { small: [1, 3], large: [2, 4]}.each do |ship_size, pads|
#   pads.each do |pad|
#     cru_l2.docks << Dock.new(
#       name: ("%02d" % pad),
#       dock_type: :landingpad,
#       ship_size: ship_size,
#     )
#   end
# end
# { large: [1, 2, 3, 4]}.each do |ship_size, hangars|
#   hangars.each do |hangar|
#     cru_l2.docks << Dock.new(
#       name: ("%02d" % hangar),
#       dock_type: :hangar,
#       ship_size: ship_size,
#     )
#   end
# end

# cru_l2.habitations.destroy_all
# %w[1 2 3 4 5].each do |level|
#   pad = 1
#   { container: 11 }.each do |hab_size, count|
#     count.times do
#       cru_l2.habitations << Habitation.new(
#         name: "Hab #{level}#{"%02d" % pad}",
#         habitation_name: 'EZ Hab',
#         habitation_type: hab_size
#       )
#       pad += 1
#     end
#   end
# end

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: cru_l2)
admin_office.update!(
  shop_type: :admin,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cru-l2/admin.jpg',
  buying: true,
  selling: true,
  hidden: hidden
)

live_fire_weapons = Shop.find_or_initialize_by(name: 'Live Fire Weapons', station: cru_l2)
live_fire_weapons.update!(
  shop_type: :weapons,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cru-l2/weapons.jpg',
  selling: true,
  hidden: hidden
)

casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: cru_l2)
casaba.update!(
  shop_type: :clothing,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cru-l2/casaba.jpg',
  selling: true,
  hidden: hidden
)

platinum_bay = Shop.find_or_initialize_by(name: 'Platinum Bay', station: cru_l2)
platinum_bay.update!(
  shop_type: :components,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/crusader/cru-l2/platinum_bay.jpg',
  selling: true,
  hidden: hidden
)
