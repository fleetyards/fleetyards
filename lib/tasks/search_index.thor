# frozen_string_literal: true

require 'thor'

class Search < Thor
  include Thor::Actions

  def self.exit_on_failure?
    true
  end

  desc 'index', 'Create index/reindex for all Relevant Models'
  def index
    require './config/environment'

    run("curl -XPUT -H \"Content-Type: application/json\" http://localhost:9200/_all/_settings -d '{\"index.blocks.read_only_allow_delete\": false}'", verbose: false)

    puts
    puts 'Starting Reindex...'
    puts

    puts Model.reindex && '--> Models Reindexed'
    puts ShopCommodity.reindex && '--> ShopCommodities Reindexed'
    puts Shop.reindex && '--> Shops Reindexed'
    puts Station.reindex && '--> Stations Reindexed'
    puts CelestialObject.reindex && '--> CelestialObjects Reindexed'
    puts Starsystem.reindex && '--> Starsystems Reindexed'

    puts
    puts 'Finished'
    puts

    run("curl -XPUT -H \"Content-Type: application/json\" http://localhost:9200/_all/_settings -d '{\"index.blocks.read_only_allow_delete\": false}'", verbose: false)
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  desc 'delete_index', 'Delete index for all Relevant Models'
  def delete_index
    require './config/environment'

    Model.search_index.delete && '--> deleted Model Index' if Model.search_index.exists?
    ShopCommodity.search_index.delete && '--> deleted ShopCommodity Index' if ShopCommodity.search_index.exists?
    Shop.search_index.delete && '--> deleted Shop Index' if Shop.search_index.exists?
    Station.search_index.delete && '--> deleted Station Index' if Station.search_index.exists?
    CelestialObject.search_index.delete && '--> deleted CelestialObject Index' if CelestialObject.search_index.exists?
    Starsystem.search_index.delete && '--> deleted Starsystem Index' if Starsystem.search_index.exists?
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
