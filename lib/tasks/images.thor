# frozen_string_literal: true

require "thor"

class Images < Thor
  include Thor::Actions

  desc "recreate", "Recreate Versions"
  def recreate
    require "./config/environment"
    Image.find_each do |image|
      begin
        image.name.cache_stored_file!
        image.name.retrieve_from_cache!(image.name.cache_name)
        image.name.recreate_versions!(:dark, :big, :small)
        image.save!
      rescue => e
        puts "ERROR: YourModel: #{ym.id} -> #{e}"
      end
    end

    Ship.find_each do |ship|
      begin
        ship.store_image.cache_stored_file!
        ship.store_image.retrieve_from_cache!(ship.store_image.cache_name)
        ship.store_image.recreate_versions!(:dark, :big, :small)
        ship.save!
      rescue => e
        puts "ERROR: YourModel: #{ym.id} -> #{e}"
      end
    end
  end
end
