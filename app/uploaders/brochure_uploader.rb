# frozen_string_literal: true

class BrochureUploader < BaseUploader
  def extension_white_list
    %w[pdf]
  end
end
