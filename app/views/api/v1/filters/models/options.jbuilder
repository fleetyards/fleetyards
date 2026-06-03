# frozen_string_literal: true

json.items @models do |model|
  json.partial! "api/v1/filters/models/option", model: model
end
json.partial! "api/shared/meta", result: @models
