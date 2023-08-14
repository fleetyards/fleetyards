# frozen_string_literal: true

json.id model.id
json.sc_identifier model.sc_identifier
json.name model.name
json.slug model.slug

json.availability do
  json.bought_at do
    json.array! model.bought_at, partial: "api/v1/shop_commodities/minimal", as: :shop_commodity
  end
  json.listed_at do
    json.array! model.listed_at, partial: "api/v1/shop_commodities/minimal", as: :shop_commodity
  end
  json.rental_at do
    json.array! model.rental_at, partial: "api/v1/shop_commodities/minimal", as: :shop_commodity
  end
  json.sold_at do
    json.array! model.sold_at, partial: "api/v1/shop_commodities/minimal", as: :shop_commodity
  end
end
json.brochure model.brochure.url
json.classification model.classification
json.classification_label model.classification&.humanize
json.crew do
  json.max model.max_crew
  json.max_label model.max_crew.to_s
  json.min model.min_crew
  json.min_label model.min_crew.to_s
end
json.description model.description
json.erkul_identifier(model.erkul_identifier.presence || model.sc_identifier)
json.focus model.focus
json.has_images model.images_count.positive?
json.has_modules model.module_hardpoints_count.positive?
json.has_paints model.model_paints_count.positive?
json.has_upgrades model.upgrade_kits_count.positive?
json.has_videos model.videos_count.positive?
json.holo model.holo.url
json.holo_colored model.holo_colored
json.last_pledge_price((model.last_pledge_price.to_f if model.last_pledge_price.present?))
json.last_pledge_price_label model.last_pledge_price_label
json.last_updated_at model.last_updated_at&.utc&.iso8601
json.last_updated_at_label((I18n.l(model.last_updated_at.utc, format: :label) if model.last_updated_at.present?))
json.links do
  json.store_url model.rsi_store_url
  json.sales_page_url model.rsi_sales_page_url
end
json.loaners do
  json.array! model.loaners, partial: "api/v1/models/loaner", as: :loaner
end
json.manufacturer do
  json.null! if model.manufacturer.blank?
  json.partial! "api/v1/manufacturers/minimal", manufacturer: model.manufacturer if model.manufacturer.present?
end
json.media do
  json.angled_view do
    json.partial! "api/v1/shared/view_image", view_image: model.angled_view, width: model.angled_view_width, height: model.angled_view_height
  end
  json.angled_view_colored do
    json.partial! "api/v1/shared/view_image", view_image: model.angled_view_colored, width: model.angled_view_colored_width, height: model.angled_view_colored_height
  end
  json.fleetchart_image model.fleetchart_image.url
  json.front_view do
    json.partial! "api/v1/shared/view_image", view_image: model.front_view, width: model.front_view_width, height: model.front_view_height
  end
  json.front_view_colored do
    json.partial! "api/v1/shared/view_image", view_image: model.front_view_colored, width: model.front_view_colored_width, height: model.front_view_colored_height
  end
  json.side_view do
    json.partial! "api/v1/shared/view_image", view_image: model.side_view, width: model.side_view_width, height: model.side_view_height
  end
  json.side_view_colored do
    json.partial! "api/v1/shared/view_image", view_image: model.side_view_colored, width: model.side_view_colored_width, height: model.side_view_colored_height
  end
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: model.store_image
  end
  json.top_view do
    json.partial! "api/v1/shared/view_image", view_image: model.top_view, width: model.top_view_width, height: model.top_view_height
  end
  json.top_view_colored do
    json.partial! "api/v1/shared/view_image", view_image: model.top_view_colored, width: model.top_view_colored_width, height: model.top_view_colored_height
  end
end
json.metrics do
  json.beam model.beam.to_f
  json.beam_label model.beam_label
  json.cargo model.cargo.to_f
  json.cargo_label model.cargo_label
  json.fleetchart_length (model.fleetchart_offset_length || model.length).to_f
  json.height model.height.to_f
  json.height_label model.height_label
  json.hydrogen_fuel_tank_size model.hydrogen_fuel_tank_size&.to_f
  json.is_ground_vehicle model.ground
  json.length model.length.to_f
  json.length_label model.length_label
  json.mass model.mass.to_f
  json.mass_label model.mass.to_f.to_s
  json.quantum_fuel_tank_size model.quantum_fuel_tank_size&.to_f
  json.size model.size
  json.size_label model.size&.humanize
end
json.on_sale model.on_sale
json.pledge_price((model.pledge_price.to_f if model.pledge_price.present?))
json.pledge_price_label model.pledge_price_label
json.price((model.price.to_f if model.price.present?))
json.price_label model.price_label
json.production_note model.production_note
json.production_status model.production_status
json.rsi_id model.rsi_id
json.rsi_name model.rsi_name
json.rsi_slug model.rsi_slug
json.speeds do
  json.ground_acceleration model.ground_acceleration&.to_f
  json.ground_decceleration model.ground_decceleration&.to_f
  json.ground_max_speed model.ground_max_speed&.to_f
  json.ground_reverse_speed model.ground_reverse_speed&.to_f
  json.max_speed model.max_speed&.to_f
  json.max_speed_acceleration model.max_speed_acceleration&.to_f
  json.max_speed_decceleration model.max_speed_decceleration&.to_f
  json.pitch model.pitch&.to_f
  json.roll model.roll&.to_f
  json.scm_speed model.scm_speed&.to_f
  json.scm_speed_acceleration model.scm_speed_acceleration&.to_f
  json.scm_speed_decceleration model.scm_speed_decceleration&.to_f
  json.yaw model.yaw&.to_f
end

# deprecated
json.afterburner_ground_speed nil
json.afterburner_speed nil
json.angled_view model.angled_view.url
json.angled_view_height model.angled_view_height
json.angled_view_large model.angled_view.large.url
json.angled_view_medium model.angled_view.medium.url
json.angled_view_small model.angled_view.small.url
json.angled_view_width model.angled_view_width
json.angled_view_xlarge model.angled_view.xlarge.url
json.beam model.beam.to_f
json.beam_label model.beam_label
json.cargo model.cargo.to_f
json.cargo_label model.cargo_label
json.fleetchart_image model.fleetchart_image.url
json.fleetchart_length (model.fleetchart_offset_length || model.length).to_f
json.ground_speed nil
json.height model.height.to_f
json.height_label model.height_label
json.hydrogen_fuel_tank_size model.hydrogen_fuel_tank_size&.to_f
json.length model.length.to_f
json.length_label model.length_label
json.mass model.mass.to_f
json.mass_label model.mass.to_f
json.max_crew model.max_crew
json.max_crew_label model.max_crew.to_s
json.min_crew model.min_crew
json.min_crew_label model.min_crew.to_s
json.pitch_max model.pitch&.to_f
json.quantum_fuel_tank_size model.quantum_fuel_tank_size&.to_f
json.roll_max model.roll&.to_f
json.sales_page_url model.rsi_sales_page_url
json.scm_speed model.scm_speed&.to_f
json.side_view model.side_view.url
json.side_view_height model.side_view_height
json.side_view_large model.side_view.large.url
json.side_view_medium model.side_view.medium.url
json.side_view_small model.side_view.small.url
json.side_view_width model.side_view_width
json.side_view_xlarge model.side_view.xlarge.url
json.size model.size
json.size_label model.size&.humanize
json.store_image model.store_image.url
json.store_image_large model.store_image.large.url
json.store_image_medium model.store_image.medium.url
json.store_image_small model.store_image.small.url
json.store_url model.rsi_store_url
json.top_view model.top_view.url
json.top_view_height model.top_view_height
json.top_view_large model.top_view.large.url
json.top_view_medium model.top_view.medium.url
json.top_view_small model.top_view.small.url
json.top_view_width model.top_view_width
json.top_view_xlarge model.top_view.xlarge.url
json.xaxis_acceleration nil
json.yaw_max model.yaw&.to_f
json.yaxis_acceleration nil
json.zaxis_acceleration nil
