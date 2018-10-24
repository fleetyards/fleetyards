# spaceport hub truckstop refinery cargo-station mining-station asteroid-station outpost
stanton = Starsystem.find_by!(slug: 'stanton')
stanton.update!(store_image: Rails.root.join('db/seeds/images/stanton.jpg').open, map_x: '59.766411599', map_y: '48.460661345')

nyx = Starsystem.find_by!(slug: 'nyx')
nyx.update!(map_x: '42.2', map_y: '22.75')
