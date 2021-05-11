# frozen_string_literal: true

class HoloUploader < BaseUploader
  def extension_white_list
    %w[glb gltf]
  end
end
