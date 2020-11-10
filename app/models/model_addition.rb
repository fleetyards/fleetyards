# frozen_string_literal: true

# == Schema Information
#
# Table name: model_additions
#
#  id                :uuid             not null, primary key
#  afterburner_speed :decimal(15, 2)
#  beam              :decimal(15, 2)   default(0.0), not null
#  cargo             :decimal(15, 2)
#  cruise_speed      :decimal(15, 2)
#  height            :decimal(15, 2)   default(0.0), not null
#  length            :decimal(15, 2)   default(0.0), not null
#  mass              :decimal(15, 2)   default(0.0), not null
#  max_crew          :integer
#  min_crew          :integer
#  net_cargo         :decimal(15, 2)
#  price             :decimal(15, 2)
#  scm_speed         :decimal(15, 2)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  model_id          :uuid             not null
#
# Indexes
#
#  index_model_additions_on_model_id  (model_id)
#
class ModelAddition < ApplicationRecord
  belongs_to :model, optional: false, touch: true
end
