# frozen_string_literal: true

json.id module_package.id
json.name module_package.name
json.description module_package.description
json.pledge_price module_package.pledge_price
json.has_store_image module_package.store_image.attached?

json.media({})
json.media do
  json.angled_view do
    json.partial! "api/v1/shared/file", record: module_package, attr: :angled_view
  end
  json.front_view do
    json.partial! "api/v1/shared/file", record: module_package, attr: :front_view
  end
  json.side_view do
    json.partial! "api/v1/shared/file", record: module_package, attr: :side_view
  end
  json.store_image do
    json.partial! "api/v1/shared/file", record: module_package, attr: :store_image
  end
  json.top_view do
    json.partial! "api/v1/shared/file", record: module_package, attr: :top_view
  end
end

json.modules do
  json.array! module_package.model_modules, partial: "api/v1/model_modules/base", as: :model_module
end

json.partial! "api/shared/dates", record: module_package
