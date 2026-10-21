# frozen_string_literal: true

# A loading screen the export carries for a build, one row per image -- a patch
# can ship more than one.
class LoadingScreen < ApplicationRecord
  include ActiveStorageVariants

  has_one_attached :image

  validates :environment, :version, :name, presence: true
  validates :name, uniqueness: {scope: :version}
end
