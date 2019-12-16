# frozen_string_literal: true

hurston = CelestialObject.find_or_create_by!(name: 'Hurston')
hurston.update!(store_image: Rails.root.join('db/seeds/images/stanton/hurston/hurston-a.jpg').open, hidden: false)

everus = Station.find_or_initialize_by(name: 'Everus Harbor')
everus.update!(
  celestial_object: hurston,
  station_type: :hub,
  location: 'Orbit',
  # store_image: Rails.root.join('db/seeds/images/stanton/hurston/everus/everus.jpg').open,
  hidden: false
)

everus.docks.destroy_all
{ small: [1, 3], large: [2, 4] }.each do |ship_size, pads|
  pads.each do |pad|
    everus.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end
{ large: [1, 2, 3, 4]}.each do |ship_size, hangars|
  hangars.each do |hangar|
    everus.docks << Dock.new(
      name: ("%02d" % hangar),
      dock_type: :hangar,
      ship_size: ship_size,
    )
  end
end

everus.habitations.destroy_all
%w[1 2 3 4 5].each do |level|
  pad = 1
  { container: 10 }.each do |hab_size, count|
    count.times do
      everus.habitations << Habitation.new(
        name: "Level #{"%02d" % level} Hab #{"%02d" % pad}",
        habitation_name: 'EZ Hab',
        habitation_type: hab_size
      )
      pad += 1
    end
  end
end

teasa_spaceport = Station.find_or_initialize_by(name: 'Teasa Spaceport')
teasa_spaceport.update!(
  celestial_object: hurston,
  station_type: :spaceport,
  location: 'Lorville',
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/teasa_spaceport.jpg').open,
  hidden: false
)
teasa_spaceport.docks.destroy_all
{ capital: [1, 10, 11], medium: [2, 3, 7], small: [6, 8, 9], large: [4, 5] }.each do |ship_size, hangars|
  hangars.each do |hangar|
    teasa_spaceport.docks << Dock.new(
      name: ("%02d" % hangar),
      dock_type: :hangar,
      ship_size: ship_size,
    )
  end
end

teasa_spaceport.habitations.destroy_all

new_deal = Shop.find_or_initialize_by(name: 'New Deal', station: teasa_spaceport)
new_deal.update!(
  shop_type: :ships,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/new_deal.png').open,
  selling: true,
  hidden: false
)

vantage_rentals = Shop.find_or_initialize_by(name: 'Vantage Rentals', station: teasa_spaceport)
vantage_rentals.update!(
  shop_type: :rental,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/vantage.jpg').open,
  rental: true,
  hidden: false
)

l19 = Station.find_or_initialize_by(name: 'L19 District', celestial_object: hurston, location: 'Lorville')
l19.update!(
  station_type: :district,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/l19/l19.jpg').open,
  hidden: false
)

l19.habitations.destroy_all
%w[1 2 3 4 5 6].each do |level|
  [['C', 6], ['B', 4]].each do |prefix|
    pad = 1
    { small_apartment: prefix[1] }.each do |apartment_size, count|
      count.times do
        l19.habitations << Habitation.new(
          name: "Level #{"%02d" % level} Apartment #{prefix[0]}#{"%02d" % pad}",
          habitation_name: 'L19 Habitations',
          habitation_type: apartment_size
        )
        pad += 1
      end
    end
  end
end

admin = Shop.find_or_initialize_by(name: 'Admin Office', station: l19)
admin.update!(
  shop_type: :admin,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/l19/admin.jpg').open,
  hidden: true
)

tammany_and_sons = Shop.find_or_initialize_by(name: 'Tammany and Sons', station: l19)
tammany_and_sons.update!(
  shop_type: :superstore,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/l19/tammany_and_sons.jpg').open,
  hidden: false
)

reclamation_n_disposal = Shop.find_or_initialize_by(name: 'Reclamation & Disposal', station: l19)
reclamation_n_disposal.update!(
  shop_type: :salvage,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/l19/reclamation_n_disposal.jpg').open,
  hidden: false
)

m_n_v = Shop.find_or_initialize_by(name: 'M & V', station: l19)
m_n_v.update!(
  shop_type: :bar,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/l19/m_n_v.jpg').open,
  hidden: false
)

maria_pure_of_heart = Shop.find_or_initialize_by(name: 'MARIA - Pure of Heart', station: l19)
maria_pure_of_heart.update!(
  shop_type: :hospital,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/l19/maria_pure_of_heart.jpg').open,
  hidden: false
)

[1, 2, 3, 4, 5, 6].each do |gateNumber|
  gate = Station.find_or_initialize_by(name: "Gate #{("%02d" % gateNumber)}", location: 'Lorville', celestial_object: hurston)
  gate.update!(
    station_type: :gate,
    store_image: Rails.root.join("db/seeds/images/stanton/hurston/gate-#{gateNumber}.jpg").open,
    hidden: false
  )
  gate.docks.destroy_all
  { small: [1, 2] }.each do |ship_size, pads|
    pads.each do |pad|
      gate.docks << Dock.new(
        name: ("%02d" % pad),
        dock_type: :vehiclepad,
        ship_size: ship_size,
      )
    end
  end
end

business_district = Station.find_or_initialize_by(name: 'Central Business District', celestial_object: hurston, location: 'Lorville')
business_district.update!(
  station_type: :district,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/business/business.jpg').open,
  hidden: false
)

transfers = Shop.find_or_initialize_by(name: 'CBD Transfers', station: business_district)
transfers.update!(
  shop_type: :resources,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/business/transfers.jpg').open,
  hidden: false
)

showcase = Shop.find_or_initialize_by(name: 'HD Showcase', station: business_district)
showcase.update!(
  shop_type: :weapons,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/business/showcase.jpg').open,
  hidden: false
)
