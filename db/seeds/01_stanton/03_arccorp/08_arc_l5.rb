# frozen_string_literal: true

arccorp = CelestialObject.find_or_create_by!(name: 'ArcCorp')

hidden = true

arc_l5 = Station.find_or_initialize_by(name: 'Rest & Relax (ARC-L5)')
arc_l5.update!(
  celestial_object: arccorp,
  station_type: :rest_stop,
  location: 'ARC-L5',
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/arc-l5/arc-l5.jpg').open,
  hidden: hidden
)