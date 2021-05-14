# frozen_string_literal: true

class HoloUploader < BaseUploader
  def extension_allowlist
    %w[glb gltf]
  end
end
