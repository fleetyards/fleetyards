# frozen_string_literal: true

module HangarPlans
  # A melted pledge goes to the buy-back list as it was first bought: an
  # upgraded standalone pledge comes back as the ship its title names, as
  # "Standalone Ships - Starlancer MAX plus Pacific Paints" for one upgraded to
  # an Ironclad Assault, its upgrades apart. A package, or a title no model
  # matches, comes back as the ship it holds now.
  module MeltedPledge
    def self.base_name(vehicle)
      title = vehicle.rsi_pledge_name.to_s
      return unless BuybackPledge::STANDALONE_PREFIX.match?(title)

      title.sub(BuybackPledge::STANDALONE_PREFIX, "").sub(BuybackPledge::TITLE_SUFFIX, "").squish.downcase.presence
    end

    # The ship each vehicle's pledge comes back as, by vehicle id.
    def self.base_models(vehicles, preload: [])
      names = vehicles.to_h { |vehicle| [vehicle.id, base_name(vehicle)] }
      models = Rsi::UpgradeTitles.models_by_name(names.values.compact, preload:)

      vehicles.to_h { |vehicle| [vehicle.id, models[names[vehicle.id]] || vehicle.model] }
    end

    def self.base_model(vehicle)
      base_models([vehicle]).fetch(vehicle.id)
    end
  end
end
