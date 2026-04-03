# frozen_string_literal: true

json.id model_module_package.id
json.name model_module_package.name
json.active model_module_package.active
json.hidden model_module_package.hidden

json.description model_module_package.description
json.pledge_price model_module_package.pledge_price

json.media({})
json.media do
  json.angled_view do
    json.partial! "api/v1/shared/file", record: model_module_package, attr: :angled_view
  end
  json.side_view do
    json.partial! "api/v1/shared/file", record: model_module_package, attr: :side_view
  end
  json.store_image do
    json.partial! "api/v1/shared/file", record: model_module_package, attr: :store_image
  end
  json.top_view do
    json.partial! "api/v1/shared/file", record: model_module_package, attr: :top_view
  end
end

json.model do
  json.partial! "admin/api/v1/models/base", model: model_module_package.model
end

json.modules do
  json.array! model_module_package.model_modules, partial: "api/v1/model_modules/base", as: :model_module
end

json.partial! "api/shared/dates", record: model_module_package
