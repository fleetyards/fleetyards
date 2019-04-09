# frozen_string_literal: true

class RoadmapItem < ApplicationRecord
  belongs_to :model, optional: true
end
