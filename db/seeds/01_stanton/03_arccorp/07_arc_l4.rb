# frozen_string_literal: true

arccorp = CelestialObject.find_or_create_by!(name: 'ArcCorp')

hidden = true

arc_l4 = Station.find_or_initialize_by(name: 'Rest & Relax (ARC-L4)')
arc_l4.update!(
  celestial_object: arccorp,
  station_type: :rest_stop,
  location: 'ARC-L4',
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/arc-l4/arc-l4.jpg').open,
  hidden: hidden
)