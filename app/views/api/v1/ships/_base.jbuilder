# encoding: utf-8
# frozen_string_literal: true

json.id ship.id
json.name ship.name
json.slug ship.slug
json.description ship.description
json.length ship.display_length.to_f
json.beam ship.display_beam.to_f
json.height ship.display_height.to_f
json.mass ship.display_mass.to_f
json.cargo ship.display_cargo
json.net_cargo ship.net_cargo
json.crew ship.display_crew
json.store_image ship.store_image.url
json.store_url store_url(ship.store_url)
json.price ship.price
json.on_sale ship.on_sale
json.production_status ship.production_status
json.production_note ship.production_note
json.powerplant_size ship.powerplant_size
json.shield_size ship.shield_size
json.classification ship.classification
json.focus ship.focus
json.rsi_id ship.rsi_id
