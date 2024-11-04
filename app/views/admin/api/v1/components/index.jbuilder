# frozen_string_literal: true

json.items do
  json.array! @components, partial: "admin/api/v1/components/component", as: :component
end
json.partial! "api/shared/meta", result: @components
