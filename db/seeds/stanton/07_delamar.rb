# frozen_string_literal: true

crusader = Planet.find_by!(name: 'Crusader')

delamar = Planet.find_or_initialize_by(name: 'Delamar')
delamar.update!(planet: crusader, store_image: Rails.root.join('db/seeds/images/delamar/delamar.jpg').open)

levski = Station.find_or_initialize_by(name: 'Levski')
levski.update!(planet: delamar, station_type: 'mining-station', location: 'Delamar', store_image: Rails.root.join('db/seeds/images/delamar/levski.jpg').open)

levski.docks.destroy_all
pad = 1
{ large: 4 }.each do |ship_size, count|
  count.times do |index|
    levski.docks << Dock.new(
      name: "Hangar #{"%02d" % pad}",
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
        name: "#{wing} #{"%02d" % pad}",
        habitation_type: :container
      )
      pad += 1
    end
  end
end

admin_office = Shop.find_or_create_by(name: 'Admin Office', station: levski)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/delamar/admin_levski.jpg').open)
dumpers_depot = Shop.find_or_create_by(name: "Dumper's Depot", station: levski, shop_type: :components)
dumpers_depot.update!(shop_type: :components, store_image: Rails.root.join('db/seeds/images/delamar/dumpers_depot_levski.jpg').open)
conscientious_objects = Shop.find_or_create_by(name: 'Conscientious Objects', station: levski, shop_type: :weapons)
conscientious_objects.update!(shop_type: :weapons, store_image: Rails.root.join('db/seeds/images/delamar/conscientious_objects_levski.jpg').open)
cordrys = Shop.find_or_create_by(name: "Cordry's", station: levski, shop_type: :armor)
cordrys.update!(shop_type: :armor, store_image: Rails.root.join('db/seeds/images/delamar/cordrys_levski.jpg').open)
grand_barter = Shop.find_or_create_by(name: 'Grand Barter', station: levski, shop_type: :clothing)
grand_barter.update!(shop_type: :clothing, store_image: Rails.root.join('db/seeds/images/delamar/grand_barter_levski.jpg').open)
hospital = Shop.find_or_create_by(name: 'Levski Hospital', station: levski, shop_type: :hospital)
hospital.update!(shop_type: :hospital, store_image: Rails.root.join('db/seeds/images/delamar/hospital_levski.jpg').open)
cafe_musain = Shop.find_or_create_by(name: 'Cafe Musáin', station: levski, shop_type: :bar)
cafe_musain.update!(shop_type: :bar, store_image: Rails.root.join('db/seeds/images/delamar/cafe_musain_levski.jpg').open)
