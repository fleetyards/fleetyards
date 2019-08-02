# frozen_string_literal: true

microtech = CelestialObject.find_or_create_by!(name: 'microTech')
microtech.update!(store_image: Rails.root.join('db/seeds/images/stanton/microtech/microtech.png').open, hidden: false)

new_babbage = Station.find_or_initialize_by(name: 'New Babbage')
new_babbage.update!(
  celestial_object: microtech,
  station_type: :spaceport,
  location: 'New Babbage',
  store_image: Rails.root.join('db/seeds/images/stanton/microtech/new-babbage-a.jpg').open,
  hidden: false
)

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

