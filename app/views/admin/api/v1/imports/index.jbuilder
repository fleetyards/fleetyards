# frozen_string_literal: true

json.items do
  json.array! @imports, partial: "admin/api/v1/imports/import", as: :import
end
json.partial! "api/shared/meta", result: @imports
