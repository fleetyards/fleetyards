# frozen_string_literal: true

json.id model.id
json.name model.name
json.rsiName model.rsi_name
json.slug model.slug
json.rsiSlug model.rsi_slug
json.description model.description
json.length model.display_length.to_f
json.beam model.display_beam.to_f
json.height model.display_height.to_f
json.mass model.display_mass.to_f
json.cargo model.display_cargo.to_f
json.cargoLabel model.cargo_label
json.min_crew model.display_min_crew
json.max_crew model.display_max_crew
json.scm_speed model.display_scm_speed
json.afterburner_speed model.display_afterburner_speed
json.ground_speed model.display_ground_speed
json.afterburner_ground_speed model.display_afterburner_ground_speed
json.pitch_max model.pitch_max
json.yaw_max model.yaw_max
json.roll_max model.roll_max
json.xaxis_acceleration model.xaxis_acceleration
json.yaxis_acceleration model.yaxis_acceleration
json.zaxis_acceleration model.zaxis_acceleration
json.size model.size
json.size_label model.size&.humanize
json.store_image model.store_image.url
json.fleetchart_image model.fleetchart_image.url
json.background_image model.random_image&.name&.url
json.brochure model.brochure.url
json.store_url rsi_store_url(model.store_url)
json.price((model.price.to_f if model.price.present?))
json.pledge_price((model.pledge_price.to_f if model.pledge_price.present?))
json.last_pledge_price((model.fallback_pledge_price.to_f if model.fallback_pledge_price.present?))
json.on_sale model.on_sale
json.production_status model.production_status
json.production_note model.production_note
json.classification model.classification
json.classification_label model.classification&.humanize
json.focus model.focus
json.rsi_id model.rsi_id
json.has_images model.images.count.positive?
json.has_videos model.videos.count.positive?
