# frozen_string_literal: true

euterpe = CelestialObject.find_or_create_by!(name: 'Euterpe')
euterpe.update!(store_image: Rails.root.join('db/seeds/images/stanton/microtech/euterpe/euterpe.jpg').open, hidden: false)

buds = Station.find_or_initialize_by(name: "Bud's Growery")
buds.update!(
  celestial_object: euterpe,
  station_type: :outpost,
  location: 'Euterpe',
  # store_image: Rails.root.join('db/seeds/images/stanton/hurston/stanhope.jpg').open,
  hidden: false
)

admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: buds)
admin_office.update!(
  shop_type: :admin,
  # store_image: Rails.root.join('db/seeds/images/stanton/hurston/stanhope_admin.jpg').open,
  buying: true,
  selling: true,
  hidden: false
)
