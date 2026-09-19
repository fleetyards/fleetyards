# frozen_string_literal: true

json.items do
  json.array! @blueprints, partial: "admin/api/v1/blueprints/blueprint", as: :blueprint
end
json.partial! "api/shared/meta", result: @blueprints
