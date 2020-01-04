# frozen_string_literal: true

arccorp = CelestialObject.find_or_create_by!(name: 'ArcCorp')

hidden = true # currently not present 3.8.0

arc_l5 = Station.find_or_initialize_by(name: 'Rest & Relax (ARC-L5)')
arc_l5.update!(
  celestial_object: arccorp,
  station_type: :rest_stop,
  location: 'ARC-L5',
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/arc-l5/arc-l5.jpg').open,
  hidden: hidden
)

# arc_l5.docks.destroy_all
# { small: [3, 4, 5, 6], medium: [1, 2, 7, 8] }.each do |ship_size, pads|
#   pads.each do |pad|
#     arc_l5.docks << Dock.new(
#       name: ("%02d" % pad),
#       dock_type: :landingpad,
#       ship_size: ship_size,
#     )
#   end
# end
# { large: [1, 2] }.each do |ship_size, hangars|
#   hangars.each do |hangar|
#     arc_l5.docks << Dock.new(
#       name: ("%02d" % hangar),
#       dock_type: :hangar,
#       ship_size: ship_size,
#     )
#   end
# end

# arc_l5.habitations.destroy_all
# %w[1 2 3 4 5].each do |level|
#   pad = 1
#   { container: 11 }.each do |hab_size, count|
#     count.times do
#       arc_l5.habitations << Habitation.new(
#         name: "Hab #{level}#{"%02d" % pad}",
#         habitation_name: 'EZ Hab',
#         habitation_type: hab_size
#       )
#       pad += 1
#     end
#   end
# end