# frozen_string_literal: true

aberdeen = CelestialObject.find_or_create_by!(name: 'Aberdeen')
aberdeen.update!(store_image: Rails.root.join('db/seeds/images/stanton/hurston/aberdeen/aberdeen.jpg').open, hidden: false)

norgaard = Station.find_or_initialize_by(name: 'HDMS-Norgaard')
norgaard.update!(celestial_object: aberdeen, station_type: :outpost, location: 'Aberdeen', store_image: Rails.root.join('db/seeds/images/stanton/hurston/aberdeen/norgaard.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: norgaard)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/hurston/aberdeen/norgaard_admin.jpg').open, hidden: false)

anderson = Station.find_or_initialize_by(name: 'HDMS-Anderson')
anderson.update!(celestial_object: aberdeen, station_type: :outpost, location: 'Aberdeen', hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: anderson)
admin_office.update!(shop_type: :admin, hidden: false)