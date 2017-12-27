# frozen_string_literal: true

class TradeCommodity < ApplicationRecord
  belongs_to :trade_hub, touch: true
  belongs_to :commodity
end
