# frozen_string_literal: true

arccorp = CelestialObject.find_or_create_by!(name: 'ArcCorp')

hidden = true

arc_l1 = Station.find_or_initialize_by(name: 'Rest & Relax (ARC-L1)')
arc_l1.update!(
  celestial_object: arccorp,
  station_type: :rest_stop,
  location: 'ARC-L1',
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/arc-l1/arc-l1.jpg').open,
  hidden: hidden
)

# arc_l1.docks.destroy_all
# { small: [], large: []}.each do |ship_size, pads|
#   pads.each do |pad|
#     arc_l1.docks << Dock.new(
#       name: "Landingpad #{"%02d" % pad}",
#       dock_type: :landingpad,
#       ship_size: ship_size,
#     )
#   end
# end
# { small: [], large: []}.each do |ship_size, hangars|
#   hangars.each do |hangar|
#     arc_l1.docks << Dock.new(
#       name: "Hangar #{"%02d" % hangar}",
#       dock_type: :hangar,
#       ship_size: ship_size,
#     )
#   end
# end