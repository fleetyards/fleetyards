# frozen_string_literal: true

euterpe = CelestialObject.find_or_create_by!(name: "Euterpe")
euterpe.update!(remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/microtech/euterpe/euterpe.jpg", hidden: false)

buds = Station.find_or_initialize_by(name: "Bud's Growery")
buds.update!(
  celestial_object: euterpe,
  station_type: :outpost,
  location: "Euterpe",
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/stanhope.jpg',
  hidden: false
)

admin_office = Shop.find_or_initialize_by(name: "Admin Office", station: buds)
admin_office.update!(
  shop_type: :admin,
  # remote_store_image_url: 'https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/hurston/stanhope_admin.jpg',
  buying: true,
  selling: true,
  hidden: false
)
