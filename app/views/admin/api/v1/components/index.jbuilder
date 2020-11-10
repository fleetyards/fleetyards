# frozen_string_literal: true

json.array! @components, partial: 'admin/api/v1/components/minimal', as: :component
