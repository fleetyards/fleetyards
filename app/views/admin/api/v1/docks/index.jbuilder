# frozen_string_literal: true

json.items do
  json.array! @docks, partial: "admin/api/v1/docks/dock", as: :dock
end

json.partial! "api/shared/meta", result: @docks
