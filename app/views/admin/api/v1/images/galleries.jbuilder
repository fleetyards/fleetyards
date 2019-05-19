# frozen_string_literal: true

json.array! @galleries, partial: 'admin/api/v1/images/filter', as: :filter
