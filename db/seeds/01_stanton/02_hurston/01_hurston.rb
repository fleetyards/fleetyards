# frozen_string_literal: true

hurston = CelestialObject.find_or_create_by!(name: 'Hurston')
hurston.update!(store_image: Rails.root.join('db/seeds/images/stanton/hurston/hurston-a.jpg').open, hidden: false)

lorville = Station.find_or_initialize_by(name: 'Lorville')
lorville.update!(
  celestial_object: hurston,
  station_type: :landing_zone,
  location: nil,
  classification: :city,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/teasa_spaceport.jpg').open,
  hidden: false
)

lorville.docks.destroy_all
{ capital: [1, 10, 11], medium: [2, 3, 7], small: [6, 8, 9], large: [4, 5] }.each do |ship_size, hangars|
  hangars.each do |hangar|
    lorville.docks << Dock.new(
      name: ("%02d" % hangar),
      dock_type: :hangar,
      ship_size: ship_size,
    )
  end
end
[1, 2, 3, 4, 5, 6].each do |gateNumber|
  { small: [1, 2] }.each do |ship_size, pads|
    pads.each do |pad|
      lorville.docks << Dock.new(
        name: ("Gate #{("%02d" % gateNumber)} Pad %02d" % pad),
        dock_type: :vehiclepad,
        ship_size: ship_size,
      )
    end
  end
end

lorville.habitations.destroy_all
%w[1 2 3 4 5 6].each do |level|
  [['C', 6], ['B', 4]].each do |prefix|
    pad = 1
    { small_apartment: prefix[1] }.each do |apartment_size, count|
      count.times do
        lorville.habitations << Habitation.new(
          name: "Level #{"%02d" % level} Apartment #{prefix[0]}#{"%02d" % pad}",
          habitation_name: 'L19 Habitations',
          habitation_type: apartment_size
        )
        pad += 1
      end
    end
  end
end

new_deal = Shop.find_or_initialize_by(name: 'New Deal', station: lorville)
new_deal.update!(
  shop_type: :ships,
  location: 'Teasa Spaceport',
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/new_deal.png').open,
  selling: true,
  hidden: false
)

vantage_rentals = Shop.find_or_initialize_by(name: 'Vantage Rentals', station: lorville)
vantage_rentals.update!(
  shop_type: :rental,
  location: 'Teasa Spaceport',
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/vantage.jpg').open,
  rental: true,
  hidden: false
)

admin = Shop.find_or_initialize_by(name: 'Admin Office', station: lorville)
admin.update!(
  shop_type: :admin,
  location: 'L19 District',
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/l19/admin.jpg').open,
  buying: true,
  selling: true,
  hidden: false
)

tammany_and_sons = Shop.find_or_initialize_by(name: 'Tammany and Sons', station: lorville)
tammany_and_sons.update!(
  shop_type: :superstore,
  location: 'L19 District',
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/l19/tammany_and_sons.jpg').open,
  selling: true,
  hidden: false
)

reclamation_n_disposal = Shop.find_or_initialize_by(name: 'Reclamation & Disposal', station: lorville)
reclamation_n_disposal.update!(
  shop_type: :salvage,
  location: 'L19 District',
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/l19/reclamation_n_disposal.jpg').open,
  hidden: false
)

m_n_v = Shop.find_or_initialize_by(name: 'M & V', station: lorville)
m_n_v.update!(
  shop_type: :bar,
  location: 'L19 District',
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/l19/m_n_v.jpg').open,
  hidden: false
)

maria_pure_of_heart = Shop.find_or_initialize_by(name: 'MARIA - Pure of Heart', station: lorville)
maria_pure_of_heart.update!(
  shop_type: :hospital,
  location: 'L19 District',
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/l19/maria_pure_of_heart.jpg').open,
  hidden: false
)

transfers = Shop.find_or_initialize_by(name: 'CBD Transfers', station: lorville)
transfers.update!(
  shop_type: :resources,
  location: 'Central Business District',
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/business/transfers.jpg').open,
  hidden: false
)

showcase = Shop.find_or_initialize_by(name: 'HD Showcase', station: lorville)
showcase.update!(
  shop_type: :weapons,
  location: 'Central Business District',
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/business/showcase.jpg').open,
  hidden: false
)
