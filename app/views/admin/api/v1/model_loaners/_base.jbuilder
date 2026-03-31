# frozen_string_literal: true

json.id model_loaner.id
json.model_id model_loaner.model_id
json.loaner_model_id model_loaner.loaner_model_id
json.hidden model_loaner.hidden

json.model do
  json.id model_loaner.model.id
  json.name model_loaner.model.name
  json.slug model_loaner.model.slug
end

json.loaner_model do
  json.id model_loaner.loaner_model.id
  json.name model_loaner.loaner_model.name
  json.slug model_loaner.loaner_model.slug
end

json.partial! "api/shared/dates", record: model_loaner
