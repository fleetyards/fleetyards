# frozen_string_literal: true

json.items do
  json.array! @components, partial: "api/v1/components/component", as: :component
end
json.partial! "api/shared/meta", result: @components
