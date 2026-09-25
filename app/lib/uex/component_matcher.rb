# frozen_string_literal: true

module Uex
  # Which `Component` a UEX item is, if any. Twelve components are called
  # "VariPuck S3 Gimbal Mount" and only one of them is the thing a shop sells;
  # guessing would put a shop price on a mount welded to one ship.
  class ComponentMatcher < ItemMatcher
    # UEX item id => our Component sc_key, for the ones no rule resolves.
    # Maintained by hand, the same as Uex::CommodityMatcher::MAPPINGS.
    #
    # Only where both sides plainly name the same part. Where several of ours
    # share the name and none is obviously the shop's, the row is reported as
    # ambiguous rather than guessed at: a wrong entry here prices a ship-bespoke
    # mount nobody can buy.
    MAPPINGS = {
      # "RN-7s" is the MISC standard nozzle; the other three of that name are
      # arm-only nozzles bolted to a Starfarer or a Starlite.
      776 => "fuel_nozzle_misc_nozzlestandard",
      # The other "Greycat ROC Ore Pod" is the game files' template entry.
      4396 => "cargo_groundvehiclemining_pod_roc"
    }.freeze

    def initialize(scope: Component.with_facts(true).catalogued)
      super
    end
  end
end
