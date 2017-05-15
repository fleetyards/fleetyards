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
        image.name.recreate_versions!(:dark, :small)
        image.save!
      rescue => e
        puts "ERROR: YourModel: #{ym.id} -> #{e}"
      end
    end
  end
end
