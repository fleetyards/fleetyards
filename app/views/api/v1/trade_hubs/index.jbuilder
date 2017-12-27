# frozen_string_literal: true

json.array! @trade_hubs, partial: 'api/v1/trade_hubs/base', as: :trade_hub
