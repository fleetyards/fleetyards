# frozen_string_literal: true

class ModelLoaner < ApplicationRecord
  belongs_to :model, touch: true
  belongs_to :loaner_model, class_name: 'Model'
end
