# frozen_string_literal: true

json.items do
  json.array! @images, partial: "admin/api/v1/images/image", locals: {extended: true}, as: :image
end
json.partial! "api/shared/meta", result: @images
