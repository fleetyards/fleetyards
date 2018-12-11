# frozen_string_literal: true

json.array! @components, partial: 'api/v1/components/minimal', as: :component
