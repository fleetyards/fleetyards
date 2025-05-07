# frozen_string_literal: true

json.id module_package.id
json.name module_package.name
json.description module_package.description
json.pledge_price module_package.pledge_price
json.has_store_image module_package.store_image.present?

json.media({})
json.media do
  # json.fleetchart_image module_package.fleetchart_image.url
  json.angled_view do
    json.partial! "api/v1/shared/view_image", record: module_package, attr: :new_angled_view, old_attr: :angled_view, width: module_package.angled_view_width, height: module_package.angled_view_height
  end
  json.front_view do
    json.partial! "api/v1/shared/view_image", record: module_package, attr: :front_view
  end
  json.side_view do
    json.partial! "api/v1/shared/view_image", record: module_package, attr: :new_side_view, old_attr: :side_view, width: module_package.side_view_width, height: module_package.side_view_height
  end
  json.store_image do
    json.partial! "api/v1/shared/view_image", record: module_package, attr: :new_store_image, old_attr: :store_image, width: module_package.store_image_width, height: module_package.store_image_height
  end
  json.top_view do
    json.partial! "api/v1/shared/view_image", record: module_package, attr: :new_top_view, old_attr: :top_view, width: module_package.top_view_width, height: module_package.top_view_height
  end
end

json.modules do
  json.array! module_package.model_modules, partial: "api/v1/model_modules/base", as: :model_module
end

json.partial! "api/shared/dates", record: module_package
