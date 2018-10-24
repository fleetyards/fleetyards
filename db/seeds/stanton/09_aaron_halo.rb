# frozen_string_literal: true

aaron_halo = CelestialObject.find_by!(slug: 'aaron-halo')
aaron_halo.update!(store_image: Rails.root.join('db/seeds/images/aaron_halo.png').open)
