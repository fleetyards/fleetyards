# frozen_string_literal: true

json.id model.id
json.name model.name
json.sc_identifier model.sc_identifier
json.erkul_identifier(model.erkul_identifier.presence || model.sc_identifier)
json.rsi_name model.rsi_name
json.slug model.slug
json.rsi_slug model.rsi_slug
json.description model.description
json.length model.length.to_f
json.length_label model.length_label
json.fleetchart_length (model.fleetchart_offset_length || model.length).to_f
json.beam model.beam.to_f
json.beam_label model.beam_label
json.height model.height.to_f
json.height_label model.height_label
json.mass model.mass.to_f
json.mass_label model.mass.to_f
json.cargo model.cargo.to_f
json.cargo_label model.cargo_label
json.hydrogen_fuel_tank_size model.hydrogen_fuel_tank_size
json.quantum_fuel_tank_size model.quantum_fuel_tank_size
json.min_crew model.min_crew
json.min_crew_label model.min_crew
json.max_crew model.max_crew
json.max_crew_label model.max_crew
json.scm_speed model.scm_speed
json.afterburner_speed model.afterburner_speed
json.ground_speed model.ground_speed
json.afterburner_ground_speed model.afterburner_ground_speed
json.pitch_max model.pitch_max
json.yaw_max model.yaw_max
json.roll_max model.roll_max
json.xaxis_acceleration model.xaxis_acceleration
json.yaxis_acceleration model.yaxis_acceleration
json.zaxis_acceleration model.zaxis_acceleration
json.size model.size
json.size_label model.size&.humanize
json.store_image model.store_image.url
json.store_image_large model.store_image.large.url
json.store_image_medium model.store_image.medium.url
json.store_image_small model.store_image.small.url
json.fleetchart_image model.fleetchart_image.url
json.top_view model.top_view.url
json.top_view_small model.top_view.small.url
json.top_view_medium model.top_view.medium.url
json.top_view_large model.top_view.large.url
json.top_view_xlarge model.top_view.xlarge.url
json.top_view_width model.top_view_width
json.top_view_height model.top_view_height
json.side_view model.side_view.url
json.side_view_small model.side_view.small.url
json.side_view_medium model.side_view.medium.url
json.side_view_large model.side_view.large.url
json.side_view_xlarge model.side_view.xlarge.url
json.side_view_width model.side_view_width
json.side_view_height model.side_view_height
json.angled_view model.angled_view.url
json.angled_view_small model.angled_view.small.url
json.angled_view_medium model.angled_view.medium.url
json.angled_view_large model.angled_view.large.url
json.angled_view_xlarge model.angled_view.xlarge.url
json.angled_view_width model.angled_view_width
json.angled_view_height model.angled_view_height
json.brochure model.brochure.url
json.holo model.holo.url
json.holo_colored model.holo_colored
json.store_url model.rsi_store_url
json.sales_page_url model.rsi_sales_page_url
json.price((model.price.to_f if model.price.present?))
json.pledge_price((model.pledge_price.to_f if model.pledge_price.present?))
json.last_pledge_price((model.last_pledge_price.to_f if model.last_pledge_price.present?))
json.on_sale model.on_sale
json.production_status model.production_status
json.production_note model.production_note
json.classification model.classification
json.classification_label model.classification&.humanize
json.focus model.focus
json.rsi_id model.rsi_id
json.has_images model.images_count.positive?
json.has_videos model.videos_count.positive?
json.has_modules model.module_hardpoints_count.positive?
json.has_upgrades model.upgrade_kits_count.positive?
json.has_paints model.model_paints_count.positive?
json.last_updated_at model.last_updated_at&.utc&.iso8601
json.last_updated_at_label((I18n.l(model.last_updated_at.utc, format: :label) if model.last_updated_at.present?))
json.sold_at do
  json.array! model.sold_at, partial: 'api/v1/shop_commodities/base', as: :shop_commodity
end
json.bought_at do
  json.array! model.bought_at, partial: 'api/v1/shop_commodities/base', as: :shop_commodity
end
json.listed_at do
  json.array! model.listed_at, partial: 'api/v1/shop_commodities/base', as: :shop_commodity
end
json.rental_at do
  json.array! model.rental_at, partial: 'api/v1/shop_commodities/base', as: :shop_commodity
end
json.manufacturer do
  json.null! if model.manufacturer.blank?
  json.partial! 'api/v1/manufacturers/base', manufacturer: model.manufacturer if model.manufacturer.present?
end
json.loaners do
  json.array! model.loaners, partial: 'api/v1/models/loaner', as: :loaner
end
