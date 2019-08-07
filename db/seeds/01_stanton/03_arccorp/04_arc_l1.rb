# frozen_string_literal: true

arccorp = CelestialObject.find_or_create_by!(name: 'ArcCorp')

hidden = false

arc_l1 = Station.find_or_initialize_by(name: 'Rest & Relax (ARC-L1)')
arc_l1.update!(
  celestial_object: arccorp,
  station_type: :rest_stop,
  location: 'ARC-L1',
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/arc-l1/arc-l1.jpg').open,
  hidden: hidden
)

arc_l1.docks.destroy_all
{ small: [1, 3], large: [2, 4]}.each do |ship_size, pads|
  pads.each do |pad|
    arc_l1.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end
{ large: [1, 2, 3, 4]}.each do |ship_size, hangars|
  hangars.each do |hangar|
    arc_l1.docks << Dock.new(
      name: ("%02d" % hangar),
      dock_type: :hangar,
      ship_size: ship_size,
    )
  end
end
