# frozen_string_literal: true

json.id model_snub_craft.id
json.model_id model_snub_craft.model_id
json.snub_craft_id model_snub_craft.snub_craft_id

json.model do
  json.id model_snub_craft.model.id
  json.name model_snub_craft.model.name
  json.slug model_snub_craft.model.slug
end

json.snub_craft do
  json.id model_snub_craft.snub_craft.id
  json.name model_snub_craft.snub_craft.name
  json.slug model_snub_craft.snub_craft.slug
end

json.partial! "api/shared/dates", record: model_snub_craft
