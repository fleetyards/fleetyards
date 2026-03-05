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
    json.partial! "api/v1/shared/file", record: model_module_package, attr: :new_angled_view, old_attr: :angled_view, width: model_module_package.angled_view_width, height: model_module_package.angled_view_height
  end
  json.side_view do
    json.partial! "api/v1/shared/file", record: model_module_package, attr: :new_side_view, old_attr: :side_view, width: model_module_package.side_view_width, height: model_module_package.side_view_height
  end
  json.store_image do
    json.partial! "api/v1/shared/file", record: model_module_package, attr: :new_store_image, old_attr: :store_image, width: model_module_package.store_image_width, height: model_module_package.store_image_height
  end
  json.top_view do
    json.partial! "api/v1/shared/file", record: model_module_package, attr: :new_top_view, old_attr: :top_view, width: model_module_package.top_view_width, height: model_module_package.top_view_height
  end
end

json.model do
  json.partial! "admin/api/v1/models/base", model: model_module_package.model
end

json.modules do
  json.array! model_module_package.model_modules, partial: "api/v1/model_modules/base", as: :model_module
end

json.partial! "api/shared/dates", record: model_module_package
