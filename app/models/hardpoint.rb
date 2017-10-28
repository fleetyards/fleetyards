# frozen_string_literal: true

class Hardpoint < ApplicationRecord
  belongs_to :model
  belongs_to :component, required: false

  validates :model_id, presence: true
end
