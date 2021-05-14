# frozen_string_literal: true

class BrochureUploader < BaseUploader
  def extension_allowlist
    %w[pdf]
  end
end
