# frozen_string_literal: true

class HoloUploader < BaseUploader
  # def move_to_cache
  #   true
  # end

  # def move_to_store
  #   true
  # end

  def extension_allowlist
    %w[glb gltf]
  end
end
