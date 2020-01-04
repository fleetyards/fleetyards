# frozen_string_literal: true

stanton = Starsystem.find_or_create_by!(name: 'Stanton')
stanton.update!(store_image: Rails.root.join('db/seeds/images/stanton/stanton.jpg').open, map_x: '59.766411599', map_y: '48.460661345', hidden: false)

nyx = Starsystem.find_or_create_by!(name: 'Nyx')
nyx.update!(store_image: Rails.root.join('db/seeds/images/nyx/nyx.jpg').open, map_x: '42.2', map_y: '22.75', hidden: false)

pyro = Starsystem.find_or_create_by!(name: 'Pyro')
pyro.update!(store_image: Rails.root.join('db/seeds/images/pyro/pyro.jpg').open, map_x: '53.5', map_y: '36', hidden: false)
