# frozen_string_literal: true

json.id module_package.id
json.name module_package.name
json.description module_package.description
json.pledge_price module_package.pledge_price
json.has_store_image module_package.store_image.present?

json.media({})
json.media do
  json.ignore_nil!
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: module_package.store_image
  end
  # json.fleetchart_image module_package.fleetchart_image.url
  json.angled_view do
    json.partial! "api/v1/shared/view_image", view_image: module_package.angled_view, width: module_package.angled_view_width, height: module_package.angled_view_height
  end
  # json.front_view do
  #   json.partial! "api/v1/shared/view_image", view_image: module_package.front_view, width: module_package.front_view_width, height: module_package.front_view_height
  # end
  json.side_view do
    json.partial! "api/v1/shared/view_image", view_image: module_package.side_view, width: module_package.side_view_width, height: module_package.side_view_height
  end
  json.top_view do
    json.partial! "api/v1/shared/view_image", view_image: module_package.top_view, width: module_package.top_view_width, height: module_package.top_view_height
  end
  # json.angled_view_colored do
  #   json.partial! "api/v1/shared/view_image", view_image: model_paint.angled_view_colored, width: model_paint.angled_view_colored_width, height: model_paint.angled_view_colored_height
  # end
  # json.front_view_colored do
  #   json.partial! "api/v1/shared/view_image", view_image: model_paint.front_view_colored, width: model_paint.front_view_colored_width, height: model_paint.front_view_colored_height
  # end
  # json.side_view_colored do
  #   json.partial! "api/v1/shared/view_image", view_image: model_paint.side_view_colored, width: model_paint.side_view_colored_width, height: model_paint.side_view_colored_height
  # end
  # json.top_view_colored do
  #   json.partial! "api/v1/shared/view_image", view_image: model_paint.top_view_colored, width: model_paint.top_view_colored_width, height: model_paint.top_view_colored_height
  # end
end

json.modules do
  json.array! module_package.model_modules, partial: "api/v1/model_modules/base", as: :model_module
end

json.partial! "api/shared/dates", record: module_package

# DEPRECATED

json.store_image module_package.store_image.url
json.store_image_large module_package.store_image.large.url
json.store_image_medium module_package.store_image.medium.url
json.store_image_small module_package.store_image.small.url
json.top_view module_package.top_view.url
json.top_view_small module_package.top_view.small.url
json.top_view_medium module_package.top_view.medium.url
json.top_view_large module_package.top_view.large.url
json.top_view_xlarge module_package.top_view.xlarge.url
json.top_view_width module_package.top_view_width
json.top_view_height module_package.top_view_height
json.side_view module_package.side_view.url
json.side_view_small module_package.side_view.small.url
json.side_view_medium module_package.side_view.medium.url
json.side_view_large module_package.side_view.large.url
json.side_view_xlarge module_package.side_view.xlarge.url
json.side_view_width module_package.side_view_width
json.side_view_height module_package.side_view_height
json.angled_view module_package.angled_view.url
json.angled_view_small module_package.angled_view.small.url
json.angled_view_medium module_package.angled_view.medium.url
json.angled_view_large module_package.angled_view.large.url
json.angled_view_xlarge module_package.angled_view.xlarge.url
json.angled_view_width module_package.angled_view_width
json.angled_view_height module_package.angled_view_height
