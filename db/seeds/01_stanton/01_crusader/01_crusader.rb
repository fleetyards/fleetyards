# frozen_string_literal: true

crusader = CelestialObject.find_or_create_by!(name: 'Crusader')
crusader.update!(store_image: Rails.root.join('db/seeds/images/stanton/crusader/crusader.jpg').open, hidden: false)