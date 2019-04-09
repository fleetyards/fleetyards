# frozen_string_literal: true

class RoadmapItem < ApplicationRecord
  audited max_audits: 5, on: [:update]

  belongs_to :model, optional: true
end
