# frozen_string_literal: true

class BaseUploader < CarrierWave::Uploader::Base
  after :store, :update_model

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}#{uuid_path}"
  end

  def filename
    return if original_filename.blank?

    if Rails.env.test?
      super
    else
      "#{File.basename(original_filename, File.extname(original_filename))}-#{secure_token}.#{file.extension}"
    end
  end

  def update_model(*args)
    # HACK to invalidate cache after upload
    model.touch
  end

  private def uuid_path
    model.id.split(/(.{2})(.{2})(.+)/).join('/')
  end

  protected def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.uuid)
  end
end
