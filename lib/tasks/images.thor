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
end
