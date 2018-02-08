# frozen_string_literal: true

class FleetchartImageUploader < CarrierWave::Uploader::Base
  storage Rails.env.production? ? :fog : :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def filename
    "#{Time.zone.now.to_i}.png" if original_filename.present?
  end

  def extension_white_list
    %w[png]
  end
end
