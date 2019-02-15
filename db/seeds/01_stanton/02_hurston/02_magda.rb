# frozen_string_literal: true

magda = CelestialObject.find_or_create_by!(name: 'Magda')
magda.update!(store_image: Rails.root.join('db/seeds/images/stanton/hurston/magda/magda.jpg').open, hidden: false)

hahn = Station.find_or_initialize_by(name: 'HDMS-Hahn')
hahn.update!(celestial_object: magda, station_type: :outpost, location: 'Magda', hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: hahn)
admin_office.update!(shop_type: :admin, hidden: false)

perlman = Station.find_or_initialize_by(name: 'HDMS-Perlman')
perlman.update!(celestial_object: magda, station_type: :outpost, location: 'Magda', store_image: Rails.root.join('db/seeds/images/stanton/hurston/magda/perlman.jpg').open, hidden: false)
admin_office = Shop.find_or_initialize_by(name: 'Admin Office', station: perlman)
admin_office.update!(shop_type: :admin, store_image: Rails.root.join('db/seeds/images/stanton/hurston/magda/perlman_admin.jpg').open, hidden: false)
