# frozen_string_literal: true

json.count model.count
json.model do
  json.partial! 'api/v1/models/minimal', model: model.model
end
