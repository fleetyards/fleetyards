# frozen_string_literal: true

json.items do
  json.array! @imports, partial: "api/v1/imports/user_import", as: :import
end
json.partial! "api/shared/meta", result: @imports
