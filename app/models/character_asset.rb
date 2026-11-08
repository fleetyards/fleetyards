# frozen_string_literal: true

# One file of the character customizer export -- an accessory mesh, a skin
# texture set, a hair or makeup texture, the item catalogue -- keyed by its
# path in the bucket, which is how the catalogue and a resolved character
# name it.
class CharacterAsset < ApplicationRecord
  has_one_attached :file

  validates :path, presence: true, uniqueness: true
end
