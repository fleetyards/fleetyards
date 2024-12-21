# frozen_string_literal: true

json.array! @commodities, partial: "api/v1/commodities/commodity", as: :commodity
