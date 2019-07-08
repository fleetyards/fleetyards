# frozen_string_literal: true

lyria = CelestialObject.find_or_create_by!(name: 'Lyria')
lyria.update!(hidden: false)

humboldt_mines = Station.find_or_initialize_by(name: 'Humboldt Mines')
humboldt_mines.update!(
  celestial_object: lyria,
  station_type: :outpost,
  location: 'Lyria',
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/lyria/humboldt.jpg').open,
  hidden: false
)
