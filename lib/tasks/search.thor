# frozen_string_literal: true

require 'thor'

class Search < Thor
  include Thor::Actions

  def self.exit_on_failure?
    true
  end

  desc 'cleanup', 'Cleanup index for all Relevant Models'
  def cleanup
    require './config/environment'

    set_elasticsearch_settings

    puts
    puts 'Starting Clenaup...'
    puts

    puts Model.search_index.clean_indices && '--> Models Reindexed'
    puts Component.search_index.clean_indices && '--> Components Reindexed'
    puts Equipment.search_index.clean_indices && '--> Equipment Reindexed'
    puts Commodity.search_index.clean_indices && '--> Commodities Reindexed'
    puts ShopCommodity.search_index.clean_indices && '--> ShopCommodities Reindexed'
    puts Shop.search_index.clean_indices && '--> Shops Reindexed'
    puts Station.search_index.clean_indices && '--> Stations Reindexed'
    puts CelestialObject.search_index.clean_indices && '--> CelestialObjects Reindexed'
    puts Starsystem.search_index.clean_indices && '--> Starsystems Reindexed'

    puts
    puts 'Finished'
    puts

    run("curl -XPUT -H \"Content-Type: application/json\" #{elasticsearch_url}/_all/_settings -d '{\"index.blocks.read_only_allow_delete\": false}'", verbose: false)
  end
  desc 'index', 'Create index/reindex for all Relevant Models'
  def index
    require './config/environment'

    set_elasticsearch_settings

    puts
    puts 'Starting Reindex...'
    puts

    puts Model.reindex && '--> Models Reindexed'
    puts Component.reindex && '--> Components Reindexed'
    puts Equipment.reindex && '--> Equipment Reindexed'
    puts Commodity.reindex && '--> Commodities Reindexed'
    puts ShopCommodity.reindex && '--> ShopCommodities Reindexed'
    puts Shop.reindex && '--> Shops Reindexed'
    puts Station.reindex && '--> Stations Reindexed'
    puts CelestialObject.reindex && '--> CelestialObjects Reindexed'
    puts Starsystem.reindex && '--> Starsystems Reindexed'

    puts
    puts 'Finished'
    puts

    run("curl -XPUT -H \"Content-Type: application/json\" #{elasticsearch_url}/_all/_settings -d '{\"index.blocks.read_only_allow_delete\": false}'", verbose: false)
  end
  # rubocop:disable Metrics/CyclomaticComplexity
  desc 'delete_index', 'Delete index for all Relevant Models'
  def delete_index
    require './config/environment'

    puts
    puts 'Starting Deletion...'
    puts

    puts Model.search_index.delete && '--> deleted Model Index' if Model.search_index.exists?
    puts ShopCommodity.search_index.delete && '--> deleted ShopCommodity Index' if ShopCommodity.search_index.exists?
    puts Component.search_index.delete && '--> deleted Component Index' if Component.search_index.exists?
    puts Equipment.search_index.delete && '--> deleted Equipment Index' if Equipment.search_index.exists?
    puts Commodity.search_index.delete && '--> deleted Commodity Index' if Commodity.search_index.exists?
    puts ShopCommodity.search_index.delete && '--> deleted ShopCommodity Index' if ShopCommodity.search_index.exists?
    puts Shop.search_index.delete && '--> deleted Shop Index' if Shop.search_index.exists?
    puts Station.search_index.delete && '--> deleted Station Index' if Station.search_index.exists?
    puts CelestialObject.search_index.delete && '--> deleted CelestialObject Index' if CelestialObject.search_index.exists?
    puts Starsystem.search_index.delete && '--> deleted Starsystem Index' if Starsystem.search_index.exists?

    puts
    puts 'Finished'
    puts
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  no_commands do
    private def elasticsearch_url
      ENV['ELASTICSEARCH_URL'] || 'http://localhost:9200'
    end

    private def set_elasticsearch_settings
      run("curl -XPUT -H \"Content-Type: application/json\" #{elasticsearch_url}/_all/_settings -d '{\"index.blocks.read_only_allow_delete\": false}'", verbose: false)
    end
  end
end
