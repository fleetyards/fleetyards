# frozen_string_literal: true

class RoadmapItem < ApplicationRecord
  MODELS_CATEGORY = 6

  audited only: %i[release tasks completed], on: [:update]

  belongs_to :model, optional: true
end
