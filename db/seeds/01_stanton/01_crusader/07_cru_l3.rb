# frozen_string_literal: true

crusader = CelestialObject.find_or_create_by!(name: 'Crusader')

hidden = true

cru_l3 = Station.find_or_initialize_by(name: 'Rest & Relax (CRU-L3)')
cru_l3.update!(
  celestial_object: crusader,
  station_type: :rest_stop,
  location: 'CRU-L3',
  # store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l3/cru-l3.jpg').open,
  hidden: hidden
)

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: cru_l3)
admin_office.update!(
  shop_type: :admin,
  # store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l3/admin.jpg').open,
  hidden: hidden
)

live_fire_weapons = Shop.find_or_initialize_by(name: 'Livefire Weapons', station: cru_l3)
live_fire_weapons.update!(
  shop_type: :weapons,
  # store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l3/weapons.jpg').open,
  hidden: hidden
)

casaba = Shop.find_or_initialize_by(name: 'Casaba Outlet', station: cru_l3)
casaba.update!(
  shop_type: :clothing,
  # store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l3/casaba.jpg').open,
  hidden: hidden
)

platinum_bay = Shop.find_or_initialize_by(name: 'Platinum Bay', station: cru_l3)
platinum_bay.update!(
  shop_type: :components,
  # store_image: Rails.root.join('db/seeds/images/stanton/crusader/cru-l3/platinum_bay.jpg').open,
  hidden: hidden
)