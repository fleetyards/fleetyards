# frozen_string_literal: true

# TODO: take new image of Delamar

delamar = CelestialObject.find_or_create_by!(name: 'Delamar')
delamar.update!(store_image: Rails.root.join('db/seeds/images/nyx/delamar/delamar.jpg').open, hidden: false)

levski = Station.find_or_initialize_by(name: 'Levski')
levski.update!(celestial_object: delamar, station_type: 'mining-hub', location: nil, store_image: Rails.root.join('db/seeds/images/nyx/delamar/levski.jpg').open, hidden: false)

levski.docks.destroy_all
pad = 1
{ large: 4 }.each do |ship_size, count|
  count.times do |index|
    levski.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :hangar,
      ship_size: ship_size
    )
    pad += 1
  end
end

levski.habitations.destroy_all
%w[A B C D].each do |wing|
  pad = 1
  { container: 16 }.each do |ship_size, count|
    count.times do
      levski.habitations << Habitation.new(
        name: ("%02d" % pad),
        habitation_name: "Wing #{wing}",
        habitation_type: :container
      )
      pad += 1
    end
  end
end

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: levski)
admin_office.update!(
  shop_type: :admin,
  store_image: Rails.root.join('db/seeds/images/nyx/delamar/admin_levski.jpg').open,
  hidden: false
)

dumpers_depot = Shop.find_or_initialize_by(name: "Dumper's Depot", station: levski)
dumpers_depot.update!(
  shop_type: :components,
  store_image: Rails.root.join('db/seeds/images/nyx/delamar/dumpers_depot_levski.jpg').open,
  hidden: false
)

conscientious_objects = Shop.find_or_initialize_by(name: 'Conscientious Objects', station: levski)
conscientious_objects.update!(
  shop_type: :weapons,
  store_image: Rails.root.join('db/seeds/images/nyx/delamar/conscientious_objects_levski.jpg').open,
  hidden: false
)

cordrys = Shop.find_or_initialize_by(name: "Cordry's", station: levski, shop_type: :armor)
cordrys.update!(
  shop_type: :armor,
  store_image: Rails.root.join('db/seeds/images/nyx/delamar/cordrys_levski.jpg').open,
  hidden: false
)

grand_barter = Shop.find_or_initialize_by(name: 'Grand Barter', station: levski)
grand_barter.update!(
  shop_type: :clothing,
  store_image: Rails.root.join('db/seeds/images/nyx/delamar/grand_barter_levski.jpg').open,
  hidden: false
)

hospital = Shop.find_or_initialize_by(name: 'Levski Hospital', station: levski)
hospital.update!(
  shop_type: :hospital,
  store_image: Rails.root.join('db/seeds/images/nyx/delamar/hospital_levski.jpg').open,
  hidden: false
)

cafe_musain = Shop.find_or_initialize_by(name: 'Cafe Musáin', station: levski)
cafe_musain.update!(
  shop_type: :bar,
  store_image: Rails.root.join('db/seeds/images/nyx/delamar/cafe_musain_levski.jpg').open,
  hidden: false
)

teachs = Shop.find_or_initialize_by(name: "Teach's Ship Shop", station: levski)
teachs.update!(
  shop_type: :ships,
  store_image: Rails.root.join('db/seeds/images/nyx/delamar/teachs.jpg').open,
  hidden: false,
  selling: true
)
