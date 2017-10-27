# frozen_string_literal: true

class ModelAddition < ApplicationRecord
  belongs_to :model, required: true, touch: true
end
