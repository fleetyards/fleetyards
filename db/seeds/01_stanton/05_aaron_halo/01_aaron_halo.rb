# frozen_string_literal: true

aaron_halo = CelestialObject.find_or_create_by!(name: "Aaron Halo")

hidden = false

aaron_halo.update!(
  remote_store_image_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/stanton/aaron_halo.jpg",
  hidden: hidden
)
