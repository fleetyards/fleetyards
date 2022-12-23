# frozen_string_literal: true

json.partial! 'api/shared/pagination_metadata', scope: @components, model: Component
json.items do
  json.array! @components, partial: 'api/v2/components/minimal', as: :component
end
