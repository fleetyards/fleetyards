# frozen_string_literal: true

arccorp = CelestialObject.find_or_create_by!(name: 'ArcCorp')

hidden = true # currently not present 3.8.0

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
#       name: ("%02d" % pad),
#       dock_type: :landingpad,
#       ship_size: ship_size,
#     )
#   end
# end
# { large: [1, 2, 3, 4]}.each do |ship_size, hangars|
#   hangars.each do |hangar|
#     arc_l2.docks << Dock.new(
#       name: ("%02d" % hangar),
#       dock_type: :hangar,
#       ship_size: ship_size,
#     )
#   end
# end

# arc_l2.habitations.destroy_all
# %w[1 2 3 4 5].each do |level|
#   pad = 1
#   { container: 11 }.each do |hab_size, count|
#     count.times do
#       arc_l2.habitations << Habitation.new(
#         name: "Hab #{level}#{"%02d" % pad}",
#         habitation_name: 'EZ Hab',
#         habitation_type: hab_size
#       )
#       pad += 1
#     end
#   end
# end