# frozen_string_literal: true

# == Schema Information
#
# Table name: model_loaners
#
#  id              :uuid             not null, primary key
#  hidden          :boolean          default(FALSE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  loaner_model_id :uuid
#  model_id        :uuid
#
class ModelLoaner < ApplicationRecord
  belongs_to :model, touch: true
  belongs_to :loaner_model, class_name: "Model"

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "hidden", "id", "loaner_model_id", "model_id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["loaner_model", "model"]
  end
end
