# frozen_string_literal: true

json.id fleetchart_layout.id
json.name fleetchart_layout.name
json.colored fleetchart_layout.colored
json.share_token fleetchart_layout.share_token
json.placements fleetchart_layout.placements, partial: "api/v1/fleetchart_layouts/placement", as: :placement
json.catalogue_placements fleetchart_layout.catalogue_placements, partial: "api/v1/fleetchart_layouts/catalogue_placement", as: :placement
json.created_at fleetchart_layout.created_at&.utc&.iso8601
json.updated_at fleetchart_layout.updated_at&.utc&.iso8601
