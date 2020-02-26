# frozen_string_literal: true

clio = CelestialObject.find_or_create_by!(name: 'Clio')
clio.update!(store_image: Rails.root.join('db/seeds/images/stanton/microtech/clio/clio.jpg').open, hidden: false)
