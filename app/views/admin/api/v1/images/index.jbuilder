# frozen_string_literal: true

json.items do
  json.array! @images, partial: "admin/api/v1/images/complete", as: :image
end
json.partial! "api/shared/meta", result: @images
