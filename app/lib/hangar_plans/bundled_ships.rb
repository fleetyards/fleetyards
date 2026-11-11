# frozen_string_literal: true

module HangarPlans
  # Buying a pledge back returns every ship it holds, not only the one a route
  # starts as. The others come along for free, each a start for another slot or
  # an extra ship in the hangar once the plan is carried out.
  module BundledShips
    BundledShip = Data.define(:pledge_start, :model, :taken_by)

    def self.for(pledge_start, models: nil)
      case pledge_start.start_kind
      when "buyback" then buyback_ships(pledge_start, models)
      when "melted" then melted_ships(pledge_start)
      else []
      end
    end

    # Each ship a plan's bought-back pledges bring along, with the start that
    # uses it, if one does.
    def self.in_plan(plan)
      starts = plan.acquisitions.where(start_kind: HangarPlanAcquisition::BUYBACK_START_KINDS)
        .includes(:hangar_plan, :start_model, :buyback_pledge, :source_vehicle, :bundled_starts).order(:created_at).to_a
      names = starts.filter_map(&:buyback_pledge).flat_map(&:returned_ship_names)
      models = names.any? ? Rsi::UpgradeTitles.models_by_name(names, preload: MODEL_PRELOAD) : {}

      starts.flat_map do |pledge_start|
        unclaimed = pledge_start.bundled_starts.sort_by(&:created_at)

        self.for(pledge_start, models:).map do |model|
          taken_by = unclaimed.find { |start| start.start_model_id == model.id }
          unclaimed.delete(taken_by)
          BundledShip.new(pledge_start:, model:, taken_by:)
        end
      end
    end

    # A pledge's ships by name, without the one the route starts as.
    private_class_method def self.buyback_ships(pledge_start, models)
      pledge = pledge_start.buyback_pledge
      return [] if pledge.nil?

      names = pledge.returned_ship_names
      models ||= Rsi::UpgradeTitles.models_by_name(names, preload: MODEL_PRELOAD)
      ships = names.filter_map { |name| models[name] }

      index = ships.index { |model| model.id == pledge_start.start_model_id }
      ships.delete_at(index) if index
      ships
    end

    # The other ships of the melted pledge. A pledge of one ship returns that
    # ship alone, as whatever it was first bought as.
    private_class_method def self.melted_ships(pledge_start)
      vehicle = pledge_start.source_vehicle
      return [] if vehicle.nil? || vehicle.rsi_pledge_id.blank?

      pledge_start.hangar_plan.pledged_vehicles.where(rsi_pledge_id: vehicle.rsi_pledge_id).where.not(id: vehicle.id)
        .where(model_id: Model.active.select(:id)).includes(model: MODEL_PRELOAD).order(:created_at).map(&:model)
    end
  end
end
