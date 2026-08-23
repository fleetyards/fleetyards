# frozen_string_literal: true

json.array! @stock, partial: "api/v1/shared/stock_position", as: :position
