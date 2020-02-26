# frozen_string_literal: true

euterpe = CelestialObject.find_or_create_by!(name: 'Euterpe')
euterpe.update!(store_image: Rails.root.join('db/seeds/images/stanton/microtech/euterpe/euterpe.jpg').open, hidden: false)
