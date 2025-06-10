# frozen_string_literal: true

module Maintenance
  class UpdateStoreImagesTask < MaintenanceTasks::Task
    no_collection

    def process
      [Component, Equipment, ModelModulePackage, ModelModule, ModelPaint, ModelUpgrade, Model].each do |klass|
        recreate(klass, "store_image")
      end

      [Model, ModelPaint].each do |klass|
        recreate(klass, "rsi_store_image")
      end
    end

    private def recreate(klass, name = "name")
      klass.find_each do |image|
        next if image.send(name).blank?

        puts image.send(name).file.filename

        image.send(name).cache_stored_file!
        image.send(name).retrieve_from_cache!(image.send(name).cache_name)
        image.send(name).recreate_versions!
        image.save!
      rescue => e
        puts "ERROR: #{klass}: #{image.id} -> #{e}"
      end
    end
  end
end
