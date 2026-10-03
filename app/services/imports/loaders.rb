# frozen_string_literal: true

module Imports
  # Every load an admin can start from the imports page, by key. The page
  # offers them in two groups -- the RSI ship matrix and the game files -- and
  # this is the one list both read, so a loader added here is one the page can
  # start.
  class Loaders
    SHIP_MATRIX = %w[ship_matrix modules paints loaners uex_vehicle_prices].freeze
    SC_DATA = %w[sc_data sc_data_models uex_commodity_prices uex_component_prices uex_equipment_prices uex_trade_routes].freeze
    # Every ship matrix load at once, which is what a new RSI patch needs.
    SHIP_MATRIX_ALL = "ship_matrix_all"
    KEYS = (SHIP_MATRIX + [SHIP_MATRIX_ALL] + SC_DATA).freeze

    def self.environments
      ::ScData::Source.configured.map(&:environment)
    end

    def initialize(key, admin_user_id:, environment: nil)
      @key = key.to_s
      @admin_user_id = admin_user_id
      @environment = environment.presence
    end

    def enqueue
      case @key
      # The rest wait for the matrix: started alongside it, they would match
      # against the ships from before the run and miss the new ones.
      when SHIP_MATRIX_ALL then ::Loaders::ModelsJob.perform_async(@admin_user_id, SHIP_MATRIX - ["ship_matrix"])
      when "ship_matrix" then ::Loaders::ModelsJob.perform_async(@admin_user_id)
      when "modules" then ::Loaders::ModulesImportJob.perform_async(@admin_user_id)
      when "paints" then ::Loaders::PaintsImportJob.perform_async(@admin_user_id)
      when "loaners" then ::Loaders::LoanerJob.perform_async(@admin_user_id)
      when "uex_vehicle_prices" then ::Loaders::UexPricesJob.perform_async(@admin_user_id)
      # By the environment's own source: the job handed an environment alone
      # would pair it with the default environment's version.
      when "sc_data" then ::Loaders::ScData::AllJob.perform_async(source.version, @admin_user_id, source.environment)
      when "sc_data_models" then ::Loaders::ScData::ModelsJob.perform_async
      when "uex_commodity_prices" then ::Loaders::UexCommodityPricesJob.perform_async(@admin_user_id)
      when "uex_component_prices" then ::Loaders::UexComponentPricesJob.perform_async(@admin_user_id)
      when "uex_equipment_prices" then ::Loaders::UexEquipmentPricesJob.perform_async(@admin_user_id)
      when "uex_trade_routes" then ::Loaders::UexTradeRoutesJob.perform_async
      else raise ArgumentError, "unknown loader: #{@key}"
      end
    end

    # Named and unknown is an error, never the default build under the wrong
    # name: a mistyped "ptu" must not start a live load.
    private def source
      return ::ScData::Source.default if @environment.nil?

      ::ScData::Source.find(@environment) || raise(ArgumentError, "unknown sc_data environment: #{@environment}")
    end
  end
end
