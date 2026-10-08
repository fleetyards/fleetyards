# frozen_string_literal: true

class ModelSnubCraft < ApplicationRecord
  belongs_to :model, touch: true
  belongs_to :snub_craft,
    class_name: "Model"

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "model_id", "snub_craft_id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["model", "snub_craft"]
  end
end
