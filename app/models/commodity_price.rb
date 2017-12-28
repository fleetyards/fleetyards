# frozen_string_literal: true

class CommodityPrice < ApplicationRecord
  validates :key, :data, presence: true
end
