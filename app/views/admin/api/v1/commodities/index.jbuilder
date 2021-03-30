# frozen_string_literal: true

json.array! @commodities, partial: 'admin/api/v1/commodities/minimal', as: :commodity
