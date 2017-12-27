# frozen_string_literal: true

json.array! @commodities, partial: 'api/v1/commodities/base', as: :commodity
