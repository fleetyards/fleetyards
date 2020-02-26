# frozen_string_literal: true

calliope = CelestialObject.find_or_create_by!(name: 'Calliope')
calliope.update!(store_image: Rails.root.join('db/seeds/images/stanton/microtech/calliope/calliope.jpg').open, hidden: false)
