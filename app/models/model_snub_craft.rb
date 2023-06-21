# frozen_string_literal: true

# == Schema Information
#
# Table name: model_snub_crafts
#
#  id            :uuid             not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  model_id      :uuid             not null
#  snub_craft_id :uuid             not null
#
class ModelSnubCraft < ApplicationRecord
  belongs_to :model, touch: true
  belongs_to :snub_craft,
    class_name: "Model"
end
