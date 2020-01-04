# frozen_string_literal: true

hurston = CelestialObject.find_or_create_by!(name: 'Hurston')

hidden = false

hur_l2 = Station.find_or_initialize_by(name: 'Rest & Relax (HUR-L2)')
hur_l2.update!(
  celestial_object: hurston,
  station_type: :rest_stop,
  location: 'HUR-L2',
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/hur-l2/hur-l2-a.jpg').open,
  hidden: hidden
)

hur_l2.docks.destroy_all
{ small: [1, 3, 4, 5], large: [2, 6] }.each do |ship_size, pads|
  pads.each do |pad|
    hur_l2.docks << Dock.new(
      name: ("%02d" % pad),
      dock_type: :landingpad,
      ship_size: ship_size,
    )
  end
end
{ large: [1, 2, 3, 4] }.each do |ship_size, hangars|
  hangars.each do |hangar|
    hur_l2.docks << Dock.new(
      name: ("%02d" % hangar),
      dock_type: :hangar,
      ship_size: ship_size,
    )
  end
end

hur_l2.habitations.destroy_all
%w[1 2 3 4 5].each do |level|
  pad = 1
  { container: 10 }.each do |hab_size, count|
    count.times do
      hur_l2.habitations << Habitation.new(
        name: "Level #{"%02d" % level} Hab #{"%02d" % pad}",
        habitation_name: 'EZ Hab',
        habitation_type: hab_size
      )
      pad += 1
    end
  end
end

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: hur_l2)
admin_office.update!(
  shop_type: :admin,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/hur-l2/admin.jpg').open,
  hidden: hidden
)

live_fire_weapons = Shop.find_or_initialize_by(name: 'Livefire Weapons', station: hur_l2)
live_fire_weapons.update!(
  shop_type: :weapons,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/hur-l2/weapons.jpg').open,
  hidden: hidden
)

ship_weapons = Shop.find_or_initialize_by(name: 'Ship Weapons', station: hur_l2)
ship_weapons.update!(
  shop_type: :weapons,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/hur-l2/ship_weapons.jpg').open,
  hidden: hidden
)

casaba = Shop.find_by(name: 'Casaba Outlet', station: hur_l2)
casaba.destroy if casaba.present?

platinum_bay = Shop.find_or_initialize_by(name: 'Platinum Bay', station: hur_l2)
platinum_bay.update!(
  shop_type: :components,
  store_image: Rails.root.join('db/seeds/images/stanton/hurston/hur-l2/platinum.jpg').open,
  hidden: hidden
)
