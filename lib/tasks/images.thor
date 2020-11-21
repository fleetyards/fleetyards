# frozen_string_literal: true

require 'thor'

class Images < Thor
  include Thor::Actions

  desc 'recreate', 'Recreate Versions'
  def recreate
    require './config/environment'

    [Image].each do |klass|
      recreate_single(klass, 'name')
    end

    [
      Component, Equipment, Station, CelestialObject, Commodity, Model, ModelPaint, ModelUpgrade,
      ModelModule, RoadmapItem, Shop, Starsystem
    ].each do |klass|
      recreate_single(klass, 'store_image')
    end

    [Model, ModelPaint].each do |klass|
      recreate_single(klass, 'rsi_store_image')
      recreate_single(klass, 'fleetchart_image')
    end
  end

  desc 'recreate_images', 'Recreate Image Versions'
  def recreate_single(klass, name = 'name')
    require './config/environment'

    model = klass.constantize

    return if model.blank?

    model.find_each do |image|
      next if image.send(name).blank?

      puts image.send(name).file.filename

      image.send(name).cache_stored_file!
      image.send(name).retrieve_from_cache!(image.send(name).cache_name)
      image.send(name).recreate_versions!
      image.save!
    rescue StandardError => e
      puts "ERROR: #{klass}: #{image.id} -> #{e}"
    end
  end
end
