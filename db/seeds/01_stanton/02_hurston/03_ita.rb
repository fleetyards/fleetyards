# frozen_string_literal: true

ita = CelestialObject.find_or_create_by!(name: 'Ita')
ita.update!(store_image: Rails.root.join('db/seeds/images/stanton/hurston/ita/ita.jpg').open, hidden: false)

ryder = Station.find_or_initialize_by(name: 'HDMS-Ryder')
ryder.update!(celestial_object: ita, station_type: :outpost, location: nil, store_image: Rails.root.join('db/seeds/images/stanton/hurston/ita/ryder.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: ryder)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/hurston/ita/ryder_admin.jpg').open, hidden: false)

ryder.docks.destroy_all
{ small: [1, 2] }.each do |ship_size, pads|
  pads.each do |pad|
    ryder.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
  end
end
{ small: [1],  medium: [2] }.each do |ship_size, pads|
  pads.each do |pad|
    ryder.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end

woodruff = Station.find_or_initialize_by(name: 'HDMS-Woodruff')
woodruff.update!(celestial_object: ita, station_type: :outpost, location: nil, store_image: Rails.root.join('db/seeds/images/stanton/hurston/ita/woodruff.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: woodruff)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/hurston/ita/woodruff_admin.jpg').open, hidden: false)

woodruff.docks.destroy_all
{ small: [1, 2] }.each do |ship_size, pads|
  pads.each do |pad|
    woodruff.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :vehiclepad,
      ship_size: ship_size,
    )
  end
end
{ small: [1],  medium: [2] }.each do |ship_size, pads|
  pads.each do |pad|
    woodruff.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end
