# encoding: utf-8
# frozen_string_literal: true

json.cache! ['v1', @fleet] do
  json.partial! 'api/v1/fleets/base', fleet: @fleet
end
