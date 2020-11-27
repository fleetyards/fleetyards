# frozen_string_literal: true

microtech = CelestialObject.find_or_create_by!(name: 'microTech')
microtech.update!(store_image: Rails.root.join('db/seeds/images/stanton/microtech/microtech.jpg').open, hidden: false)

new_babbage_spaceport = Station.find_or_initialize_by(name: 'New Babbage Interstellar Spaceport')
new_babbage_spaceport.update!(
  celestial_object: microtech,
  station_type: :spaceport,
  location: 'New Babbage',
  store_image: Rails.root.join('db/seeds/images/stanton/microtech/new-babbage-spaceport.jpg').open,
  hidden: false
)

new_babbage_spaceport.docks.destroy_all
{ small: [1, 2, 3, 4, 5, 6], medium: [7, 9, 10, 11, 12, 13, 14, 15], large: [8, 17, 20], capital: [16, 18, 19] }.each do |ship_size, pads|
  pads.each do |pad|
    new_babbage_spaceport.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :hangar,
      ship_size: ship_size,
    )
  end
end

new_babbage = Station.find_by(name: 'New Babbage')&.destroy

aspire = Station.find_or_initialize_by(name: 'Aspire Grand')
aspire.update!(
  celestial_object: microtech,
  station_type: :poi,
  location: 'New Babbage',
  hidden: false
)

aspire.habitations.destroy_all
%w[1 2 3 4 5 6 7 8 9 10].each do |level|
  pad = 1
  { small_apartment: 5 }.each do |apartment_size, count|
    count.times do
      aspire.habitations << Habitation.new(
        name: "Level #{"%02d" % level} Apartment #{"%02d" % pad}",
        habitation_name: 'The Nest Apartments',
        habitation_type: apartment_size
      )
      pad += 1
    end
  end
end

brentworth = Shop.find_or_initialize_by(name: 'BRENTWORTH - CARE CENTER', station: aspire)
brentworth.update!(
  shop_type: :hospital,
  hidden: false
)

commons = Station.find_or_initialize_by(name: 'The Commons')
commons.update!(
  celestial_object: microtech,
  station_type: :district,
  location: 'New Babbage',
  store_image: Rails.root.join('db/seeds/images/stanton/microtech/new-babbage-a.jpg').open,
  hidden: false
)

planetary_services = Shop.find_or_initialize_by(name: 'Planetary Services', station: commons)
planetary_services.update!(
  shop_type: :admin,
  buying: true,
  selling: true,
  hidden: false
)

tdd = Shop.find_or_initialize_by(name: 'Trade & Development Devision', station: commons)
tdd.update!(
  shop_type: :resources,
  buying: true,
  selling: true,
  hidden: false
)

center_mass = Shop.find_or_initialize_by(name: 'CenterMass', station: commons)
center_mass.update!(
  shop_type: :weapons,
  selling: true,
  hidden: false
)

omega = Shop.find_or_initialize_by(name: 'Omega Pro', station: commons)
omega.update!(
  shop_type: :components,
  selling: true,
  hidden: false
)

factory_line = Shop.find_or_initialize_by(name: 'Factory Line', station: commons)
factory_line.update!(
  shop_type: :computers,
  selling: true,
  hidden: false
)

shubin_interstellar = Shop.find_or_initialize_by(name: 'Shubin Interstellar', station: commons)
shubin_interstellar.update!(
  shop_type: :mining_equipment,
  selling: true,
  hidden: false
)

ftl = Shop.find_or_initialize_by(name: 'FTL Courier', station: commons)
ftl.update!(
  shop_type: :courier,
  hidden: false
)

