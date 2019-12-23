# frozen_string_literal: true

microtech = CelestialObject.find_or_create_by!(name: 'microTech')
microtech.update!(store_image: Rails.root.join('db/seeds/images/stanton/microtech/microtech.jpg').open, hidden: false)

new_babbage_spaceport = Station.find_or_initialize_by(name: 'New Babbage Interstellar Spaceport')
new_babbage_spaceport.update!(
  celestial_object: microtech,
  station_type: :spaceport,
  location: 'New Babbage',
  store_image: Rails.root.join('db/seeds/images/stanton/microtech/new-babbage-spaceport.jpg').open,
  hidden: false
)

# new_babbage_spaceport.docks.destroy_all
# { small: [1, 3], large: [2, 4] }.each do |ship_size, pads|
#   pads.each do |pad|
#     new_babbage_spaceport.docks << Dock.new(
#       name: ("%02d" % pad),
#       dock_type: :landingpad,
#       ship_size: ship_size,
#     )
#   end
# end
# { large: [1, 2, 3, 4]}.each do |ship_size, hangars|
#   hangars.each do |hangar|
#     new_babbage_spaceport.docks << Dock.new(
#       name: ("%02d" % hangar),
#       dock_type: :hangar,
#       ship_size: ship_size,
#     )
#   end
# end

new_babbage = Station.find_or_initialize_by(name: 'New Babbage')
new_babbage.update!(
  celestial_object: microtech,
  station_type: :district,
  location: 'New Babbage',
  store_image: Rails.root.join('db/seeds/images/stanton/microtech/new-babbage-a.jpg').open,
  hidden: false
)

# new_babbage.habitations.destroy_all
# %w[1 2 3 4 5].each do |level|
#   pad = 1
#   { container: 10 }.each do |hab_size, count|
#     count.times do
#       new_babbage.habitations << Habitation.new(
#         name: "Level #{"%02d" % level} Hab #{"%02d" % pad}",
#         habitation_name: 'EZ Hab',
#         habitation_type: hab_size
#       )
#       pad += 1
#     end
#   end
# end

tdd = Shop.find_or_initialize_by(name: 'Trade & Development Devision', station: new_babbage)
tdd.update!(
  shop_type: :resources,
  # store_image: Rails.root.join('db/seeds/images/stanton/microtech/tdd.png').open,
  selling: true,
  hidden: true
)

center_mass = Shop.find_or_initialize_by(name: 'CenterMass', station: new_babbage)
center_mass.update!(
  shop_type: :weapons,
  # store_image: Rails.root.join('db/seeds/images/stanton/microtech/center_mass.png').open,
  selling: true,
  hidden: true
)

factory_line = Shop.find_or_initialize_by(name: 'CenterMass', station: new_babbage)
factory_line.update!(
  shop_type: :computers,
  # store_image: Rails.root.join('db/seeds/images/stanton/microtech/factory_line.png').open,
  selling: true,
  hidden: true
)

# shubin_interstellar

# planetary_services

