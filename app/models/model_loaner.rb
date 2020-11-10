# frozen_string_literal: true

# == Schema Information
#
# Table name: model_loaners
#
#  id              :uuid             not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  loaner_model_id :uuid
#  model_id        :uuid
#
class ModelLoaner < ApplicationRecord
  belongs_to :model, touch: true
  belongs_to :loaner_model, class_name: 'Model'
end
