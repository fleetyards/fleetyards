# frozen_string_literal: true

lyria = CelestialObject.find_or_create_by!(name: 'Lyria')
lyria.update!(store_image: Rails.root.join('db/seeds/images/stanton/arccorp/lyria/lyria.jpg').open, hidden: false)

humboldt_mines = Station.find_or_initialize_by(name: 'Humboldt Mines')
humboldt_mines.update!(
  celestial_object: lyria,
  station_type: :outpost,
  location: nil,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/lyria/humboldt.jpg').open,
  hidden: false
)

admin_office_humboldt_mines = Shop.find_or_initialize_by(name: 'Admin Office', station: humboldt_mines)
admin_office_humboldt_mines.update!(
  shop_type: :admin,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/lyria/humboldt_admin.jpg').open,
  hidden: false
)

humboldt_mines.docks.destroy_all

shubin_sal_5 = Station.find_or_initialize_by(name: 'Schubin Mining Facility SAL-5')
shubin_sal_5.update!(
  celestial_object: lyria,
  station_type: :outpost,
  location: nil,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/lyria/shubin_sal_5.jpg').open,
  hidden: false
)

shubin_sal_5.docks.destroy_all
{ small: [1, 2] }.each do |ship_size, pads|
  pads.each do |pad|
    shubin_sal_5.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
  end
end
{ small: [1],  medium: [2] }.each do |ship_size, pads|
  pads.each do |pad|
    shubin_sal_5.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end

admin_office_shubin_sal_5 = Shop.find_or_initialize_by(name: 'Admin Office', station: shubin_sal_5)
admin_office_shubin_sal_5.update!(
  shop_type: :admin,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/lyria/shubin_sal_5_admin.jpg').open,
  hidden: false
)

shubin_sal_2 = Station.find_or_initialize_by(name: 'Schubin Mining Facility SAL-2')
shubin_sal_2.update!(
  celestial_object: lyria,
  station_type: :outpost,
  location: nil,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/lyria/shubin_sal_2.jpg').open,
  hidden: false
)

shubin_sal_2.docks.destroy_all
{ small: [1, 2] }.each do |ship_size, pads|
  pads.each do |pad|
    shubin_sal_2.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
  end
end
{ small: [1],  medium: [2] }.each do |ship_size, pads|
  pads.each do |pad|
    shubin_sal_2.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end

admin_office_shubin_sal_2 = Shop.find_or_initialize_by(name: 'Admin Office', station: shubin_sal_2)
admin_office_shubin_sal_2.update!(
  shop_type: :admin,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/lyria/shubin_sal_2_admin.jpg').open,
  hidden: false
)

loveridge = Station.find_or_initialize_by(name: 'Loveridge Mineral Reserve')
loveridge.update!(
  celestial_object: lyria,
  station_type: :outpost,
  location: nil,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/lyria/loveridge.jpg').open,
  hidden: false
)

admin_office_loveridge = Shop.find_or_initialize_by(name: 'Admin Office', station: loveridge)
admin_office_loveridge.update!(
  shop_type: :admin,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/lyria/loveridge_admin.jpg').open,
  hidden: false
)

paradise = Station.find_or_initialize_by(name: 'Paradise Cove')
paradise.update!(
  celestial_object: lyria,
  station_type: :drug_lab,
  location: nil,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/lyria/paradise.jpg').open,
  hidden: true
)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: paradise)
admin_office.update!(
  shop_type: :admin,
  store_image: Rails.root.join('db/seeds/images/stanton/arccorp/lyria/paradise_admin.jpg').open,
  hidden: true
)

orphanage = Station.find_or_initialize_by(name: 'The Orphanage')
orphanage.update!(
  celestial_object: lyria,
  station_type: :drug_lab,
  location: nil,
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/lyria/orphanage.jpg').open,
  hidden: true
)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: orphanage)
admin_office.update!(
  shop_type: :admin,
  # store_image: Rails.root.join('db/seeds/images/stanton/arccorp/lyria/orphanage_admin.jpg').open,
  hidden: true
)
