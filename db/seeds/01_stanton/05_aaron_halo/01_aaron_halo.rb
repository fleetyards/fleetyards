# frozen_string_literal: true

aaron_halo = CelestialObject.find_or_create_by!(name: 'Aaron Halo')

hidden = false

aaron_halo.update!(
  store_image: Rails.root.join('db/seeds/images/stanton/aaron_halo.jpg').open,
  hidden: hidden
)
