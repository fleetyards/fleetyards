# frozen_string_literal: true

json.id dock_addition.id
json.dock_id dock_addition.dock_id
json.model_id dock_addition.model_id
json.model_name dock_addition.model.name
json.model_slug dock_addition.model.slug

json.partial! "api/shared/dates", record: dock_addition
