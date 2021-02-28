# frozen_string_literal: true

class TradingData < Thor
  include Thor::Actions

  desc 'import', 'Import Trading data from json'
  def import
    require './config/environment'

    ::TradingData::Importer.new.run
  end

  desc 'export', 'Export Trading data to json'
  def export
    require './config/environment'

    ::TradingData::Exporter.new.run
  end
end
