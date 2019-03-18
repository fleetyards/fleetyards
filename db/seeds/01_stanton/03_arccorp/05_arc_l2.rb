# frozen_string_literal: true

arccorp = CelestialObject.find_or_create_by!(name: 'ArcCorp')

hidden = true

arc_l2 = Station.find_or_initialize_by(name: 'Rest & Relax (ARC-L2)')
arc_l2.update!(
  celestial_object: arccorp,
  station_type: :rest_stop,
  location: 'ARC-L2',
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/arc-l2/arc-l2.jpg').open,
  hidden: hidden
)