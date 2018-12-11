# frozen_string_literal: true

json.cache! ['v1', component] do
  json.partial! 'api/v1/components/base', component: component
  json.manufacturer do
    json.null! if component.manufacturer.blank?
    json.partial! 'api/v1/manufacturers/base', manufacturer: component.manufacturer if component.manufacturer.present?
  end
  json.partial! 'api/shared/dates', record: component
end
