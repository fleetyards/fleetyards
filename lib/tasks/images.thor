# frozen_string_literal: true

require 'thor'

class Images < Thor
  include Thor::Actions

  desc 'recreate', 'Recreate Versions'
  def recreate
    require './config/environment'

    Image.find_each do |image|
      image.name.cache_stored_file!
      image.name.retrieve_from_cache!(image.name.cache_name)
      image.name.recreate_versions!(:dark, :big, :small)
      image.save!
    rescue StandardError => e
      puts "ERROR: YourModel: #{ym.id} -> #{e}"
    end

    Model.find_each do |model|
      model.store_image.cache_stored_file!
      model.store_image.retrieve_from_cache!(model.store_image.cache_name)
      model.store_image.recreate_versions!(:dark, :big, :small)
      model.save!
    rescue StandardError => e
      puts "ERROR: YourModel: #{ym.id} -> #{e}"
    end
  end

  desc 'set_dimensions', 'Set Dimensions'
  def set_dimensions
    require './config/environment'

    Image.find_each do |image|
      next if image.width.present? && image.height.present?

      image.name.cache_stored_file!
      image.name.retrieve_from_cache!(image.name.cache_name)
      dimensions = image.dimensions
      image.width = dimensions.width
      image.height = dimensions.height
      image.save!
    rescue StandardError => e
      puts "ERROR: YourModel: #{ym.id} -> #{e}"
    end
  end

  desc 'migrate', 'Migrate'
  def migrate
    require './config/environment'
    require 'fileutils'

    [
      'celestial_object/store_image',
      'equipment/store_image',
      'image/name',
      'manufacturer/logo',
      'model/brochure',
      'model/fleetchart_image',
      'model/image',
      'model/store_image',
      'model_module/store_image',
      'model_upgrade/store_image',
      'planet/store_image',
      'shop/store_image',
      'starsystem/store_image',
      'station/store_image'
    ].each do |model_path|
      Dir[Rails.root.join("public/uploads/#{model_path}/**/*.*")].each do |image|
        image_dirs = File.dirname(image).split('/')

        image_id = image_dirs.pop
        image_id_parts = [image_id.slice(0, 2), image_id.slice(2, 2), image_id.slice(4, 32)]

        image_name = File.basename(image)
        dir_name = "#{image_dirs.join('/')}/#{image_id_parts.join('/')}"
        destination = "#{dir_name}/#{image_name}"

        puts "Moving image to #{destination}"
        FileUtils.mkdir_p(dir_name)
        FileUtils.copy(image, destination)
      end
    end
  end

  desc 'cleanup_migrate', 'Cleanup migration'
  def cleanup_migrate
    require './config/environment'
    require 'fileutils'

    [
      'celestial_object/store_image',
      'equipment/store_image',
      'image/name',
      'manufacturer/logo',
      'model/brochure',
      'model/fleetchart_image',
      'model/image',
      'model/store_image',
      'model_module/store_image',
      'model_upgrade/store_image',
      'planet/store_image',
      'shop/store_image',
      'starsystem/store_image',
      'station/store_image'
    ].each do |model_path|
      Dir[Rails.root.join("public/uploads/#{model_path}/*")].each do |dir|
        name = File.basename(dir)
        next unless name.size == 36

        FileUtils.rm_rf(dir)
      end
    end
  end
end
