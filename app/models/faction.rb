# frozen_string_literal: true

# == Schema Information
#
# Table name: factions
#
#  id         :uuid             not null, primary key
#  code       :string
#  color      :string
#  name       :string
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  rsi_id     :integer
#
class Faction < ApplicationRecord
  before_save :update_slugs
end
