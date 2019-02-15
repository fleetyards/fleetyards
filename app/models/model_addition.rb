# frozen_string_literal: true

class ModelAddition < ApplicationRecord
  belongs_to :model, optional: false, touch: true
end
