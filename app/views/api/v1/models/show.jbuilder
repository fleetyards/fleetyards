# encoding: utf-8
# frozen_string_literal: true

json.cache! ['v1', @model] do
  json.partial! 'api/v1/models/complete', model: @model
end
