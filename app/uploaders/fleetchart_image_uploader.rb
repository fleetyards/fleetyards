# frozen_string_literal: true

class FleetchartImageUploader < BaseUploader
  def extension_white_list
    %w[png]
  end
end
