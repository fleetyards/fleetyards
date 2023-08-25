# frozen_string_literal: true

json.array! @components, partial: "admin/api/v1/components/component", as: :component
