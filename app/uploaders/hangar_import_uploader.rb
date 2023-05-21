# frozen_string_literal: true

class HangarImportUploader < BaseUploader
  def extension_allowlist
    %w[json]
  end
end
