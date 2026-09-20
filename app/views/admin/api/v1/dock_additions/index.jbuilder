# frozen_string_literal: true

json.items do
  json.array! @dock_additions, partial: "admin/api/v1/dock_additions/dock_addition", as: :dock_addition
end

json.partial! "api/shared/meta", result: @dock_additions
