# frozen_string_literal: true

json.items @manufacturers do |manufacturer|
  json.partial! "api/v1/filters/manufacturers/option", manufacturer: manufacturer
end
json.partial! "api/shared/meta", result: @manufacturers
