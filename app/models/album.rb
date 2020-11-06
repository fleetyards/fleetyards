# frozen_string_literal: true

# == Schema Information
#
# Table name: albums
#
#  id         :uuid             not null, primary key
#  enabled    :boolean          default(FALSE), not null
#  name       :string(255)
#  slug       :string(255)
#  created_at :datetime
#  updated_at :datetime
#
class Album < ApplicationRecord
  has_many :images,
           as: :gallery,
           dependent: :nullify,
           inverse_of: :album

  before_save :update_slugs
end
