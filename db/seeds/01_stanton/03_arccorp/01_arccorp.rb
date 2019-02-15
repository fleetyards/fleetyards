# frozen_string_literal: true

arccorp = CelestialObject.find_or_create_by!(name: 'ArcCorp')
arccorp.update!(store_image: Rails.root.join('db/seeds/images/stanton/arccorp/arccorp.png').open, hidden: false)

area18 = Station.find_or_initialize_by(name: 'Area 18')
area18.update!(celestial_object: arccorp, station_type: :spaceport, location: 'Area 18', store_image: Rails.root.join('db/seeds/images/stanton/arccorp/area18.jpg').open, hidden: false)
