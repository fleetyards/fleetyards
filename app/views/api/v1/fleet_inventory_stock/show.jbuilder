# frozen_string_literal: true

json.partial! "api/v1/shared/stock_item", stock_item: @stock_item

json.partial! "api/v1/shared/stock_holders", shares: @holder_balances.for_position(@stock_item.position_id)
