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
      4396 => "cargo_groundvehiclemining_pod_roc",
      # UEX files the M2C under turrets, but neither PDC turret is purchasable;
      # the gun is, and it is what the Ship Weapons shops sell.
      5139 => "behr_laserrepeater_pdc_s1",
      # UEX lists it at size 2; the size 3 one misspells its key "broudspec".
      5535 => "radr_chco_s02_broadspec_lite",
      # The piercing variant is referenced by nothing in the game files.
      5520 => "radr_grnp_s01_ecouter",
      # A shop sells the empty tank; the prefilled ones differ only in the fuel
      # they spawn with.
      5770 => "fuelpod_grin_fastandsmall",
      5771 => "fuelpod_grin_bigandfast",
      5772 => "fuelpod_stor_bigandslow",
      5773 => "fuelpod_shin_abitquickerthanstandard",
      5774 => "fuelpod_shin_fastandinsecure",
      # UEX leaves "Flight Blade" off the MPUV blades. The 1C is the base hull and
      # the 1P the passenger one, keyed as "transport".
      4852 => "controller_flight_argo_mpuv_1t_flight_blade_hnd",
      4853 => "controller_flight_argo_mpuv_1t_flight_blade_spd",
      4854 => "controller_flight_argo_mpuv_flight_blade_hnd",
      4855 => "controller_flight_argo_mpuv_flight_blade_spd",
      4856 => "controller_flight_argo_mpuv_transport_flight_blade_hnd",
      4857 => "controller_flight_argo_mpuv_transport_flight_blade_spd"
    }.freeze

    def initialize(scope: Component.with_facts(true).catalogued)
      super
    end
  end
end
