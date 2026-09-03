# frozen_string_literal: true

json.id model_sale.id
json.started_at model_sale.started_at
json.ended_at model_sale.ended_at
json.ongoing model_sale.ongoing?
json.duration_in_days model_sale.duration_in_days
