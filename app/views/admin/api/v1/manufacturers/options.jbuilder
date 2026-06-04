# frozen_string_literal: true

json.items @manufacturers do |manufacturer|
  json.partial! "admin/api/v1/manufacturers/option", manufacturer: manufacturer
end
json.partial! "api/shared/meta", result: @manufacturers
