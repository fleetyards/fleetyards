# frozen_string_literal: true

class BaseUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{uuid_path}"
  end

  private def uuid_path
    model.id.split(/(.{2})(.{2})(.+)/).join('/')
  end
end
