# frozen_string_literal: true

class FleetchartImageUploader < BaseUploader
  include CarrierWave::MiniMagick

  version :small do
    process resize_to_limit: [600, 600]
  end

  version :resized do
    process resize_to_limit: [1200, 1200], if: :size_small?
    process resize_to_limit: [2200, 2200], if: :size_medium?
    process resize_to_limit: [4000, 4000], if: :size_large?
  end

  def size_small?(_new_file)
    model.length < 40
  end

  def size_medium?(_new_file)
    model.length < 100
  end

  def size_large?(_new_file)
    model.length >= 100
  end

  def extension_allowlist
    %w[png]
  end
end
