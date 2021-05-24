# frozen_string_literal: true

# == Schema Information
#
# Table name: model_hardpoint_loadouts
#
#  id                 :uuid             not null, primary key
#  name               :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  component_id       :uuid
#  model_hardpoint_id :uuid
#
class ModelHardpointLoadout < ApplicationRecord
  belongs_to :model_hardpoint
  belongs_to :component, optional: true
end
