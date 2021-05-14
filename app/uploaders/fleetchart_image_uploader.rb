# frozen_string_literal: true

class FleetchartImageUploader < BaseUploader
  def extension_allowlist
    %w[png]
  end
end
