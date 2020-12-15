# frozen_string_literal: true

microtech = CelestialObject.find_or_create_by!(name: 'microTech')
microtech.update!(store_image: Rails.root.join('db/seeds/images/stanton/microtech/microtech.jpg').open, hidden: false)

new_babbage = Station.find_or_initialize_by(name: 'New Babbage')
new_babbage.update!(
  celestial_object: microtech,
  station_type: :landing_zone,
  classification: :city,
  location: nil,
  store_image: Rails.root.join('db/seeds/images/stanton/microtech/new-babbage-a.jpg').open,
  hidden: false
)

new_babbage.docks.destroy_all
{ small: [1, 2, 3, 4, 5, 6], medium: [7, 9, 10, 11, 12, 13, 14, 15], large: [8, 17, 20], capital: [16, 18, 19] }.each do |ship_size, pads|
  pads.each do |pad|
    new_babbage.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :hangar,
      ship_size: ship_size,
    )
  end
end

new_babbage.habitations.destroy_all
%w[1 2 3 4 5 6 7 8 9 10].each do |level|
  pad = 1
  { small_apartment: 5 }.each do |apartment_size, count|
    count.times do
      new_babbage.habitations << Habitation.new(
        name: "Level #{"%02d" % level} Apartment #{"%02d" % pad}",
        habitation_name: 'The Nest Apartments - Aspire Grand',
        habitation_type: apartment_size
      )
      pad += 1
    end
  end
end

brentworth = Shop.find_or_initialize_by(name: 'BRENTWORTH - CARE CENTER', station: new_babbage)
brentworth.update!(
  shop_type: :hospital,
  location: 'Aspire Grand',
  hidden: false
)

planetary_services = Shop.find_or_initialize_by(name: 'Planetary Services', station: new_babbage)
planetary_services.update!(
  shop_type: :admin,
  location: 'The Commons',
  buying: true,
  selling: true,
  hidden: false
)

tdd = Shop.find_or_initialize_by(name: 'Trade & Development Division', station: new_babbage)
tdd.update!(
  shop_type: :resources,
  location: 'The Commons',
  buying: true,
  selling: true,
  hidden: false
)

center_mass = Shop.find_or_initialize_by(name: 'CenterMass', station: new_babbage)
center_mass.update!(
  shop_type: :weapons,
  location: 'The Commons',
  selling: true,
  hidden: false
)

omega = Shop.find_or_initialize_by(name: 'Omega Pro', station: new_babbage)
omega.update!(
  shop_type: :components,
  location: 'The Commons',
  selling: true,
  hidden: false
)

factory_line = Shop.find_or_initialize_by(name: 'Factory Line', station: new_babbage)
factory_line.update!(
  shop_type: :computers,
  location: 'The Commons',
  selling: true,
  hidden: false
)

shubin_interstellar = Shop.find_or_initialize_by(name: 'Shubin Interstellar', station: new_babbage)
shubin_interstellar.update!(
  shop_type: :mining_equipment,
  location: 'The Commons',
  selling: true,
  hidden: false
)

ftl = Shop.find_or_initialize_by(name: 'FTL Courier', station: new_babbage)
ftl.update!(
  shop_type: :courier,
  location: 'The Commons',
  hidden: false
)

