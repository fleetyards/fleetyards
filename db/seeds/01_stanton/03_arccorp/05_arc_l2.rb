# frozen_string_literal: true

arccorp = CelestialObject.find_or_create_by!(name: 'ArcCorp')

hidden = true # currently not present 2019-07-28

arc_l2 = Station.find_or_initialize_by(name: 'Rest & Relax (ARC-L2)')
arc_l2.update!(
  celestial_object: arccorp,
  station_type: :rest_stop,
  location: 'ARC-L2',
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/arc-l2/arc-l2.jpg').open,
  hidden: hidden
)

# arc_l2.docks.destroy_all
# { small: [1, 3], large: [2, 4]}.each do |ship_size, pads|
#   pads.each do |pad|
#     arc_l2.docks << Dock.new(
#       name: "Landingpad #{"%02d" % pad}",
#       dock_type: :landingpad,
#       ship_size: ship_size,
#     )
#   end
# end
# { large: [1, 2, 3, 4]}.each do |ship_size, hangars|
#   hangars.each do |hangar|
#     arc_l2.docks << Dock.new(
#       name: "Hangar #{"%02d" % hangar}",
#       dock_type: :hangar,
#       ship_size: ship_size,
#     )
#   end
# end
