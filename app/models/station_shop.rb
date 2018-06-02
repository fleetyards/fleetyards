# frozen_string_literal: true

class StationShop < ApplicationRecord
  belongs_to :station,
             touch: true
  belongs_to :shop
end
