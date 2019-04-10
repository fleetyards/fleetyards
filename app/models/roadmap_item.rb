# frozen_string_literal: true

class RoadmapItem < ApplicationRecord
  audited only: %i[release tasks completed], on: [:update]

  belongs_to :model, optional: true
end
