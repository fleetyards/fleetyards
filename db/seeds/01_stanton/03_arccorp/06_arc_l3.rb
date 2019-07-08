# frozen_string_literal: true

arccorp = CelestialObject.find_or_create_by!(name: 'ArcCorp')

hidden = true

arc_l3 = Station.find_or_initialize_by(name: 'Rest & Relax (ARC-L3)')
arc_l3.update!(
  celestial_object: arccorp,
  station_type: :rest_stop,
  location: 'ARC-L3',
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/arc-l3/arc-l3.jpg').open,
  hidden: hidden
)