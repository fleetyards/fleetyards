# frozen_string_literal: true

microtech = CelestialObject.find_or_create_by!(name: 'microTech')
microtech.update!(store_image: Rails.root.join('db/seeds/images/microtech/microtech.png').open, hidden: false)

new_babbage = Station.find_or_initialize_by(name: 'New Babbage')
new_babbage.update!(celestial_object: microtech, station_type: :spaceport, location: 'New Babbage', store_image: Rails.root.join('db/seeds/images/microtech/new-babbage.jpg').open, hidden: false)
