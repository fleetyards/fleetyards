module ScData
  module Parser
    # What a mining module or a hand-held mining gadget does to a laser. Read the
    # same way wherever the game attaches one.
    module MiningModifiers
      MINING_MODIFIERS = {
        instability: "laserInstability",
        resistance: "resistanceModifier",
        optimal_charge_window: "optimalChargeWindowSizeModifier",
        optimal_charge_rate: "optimalChargeWindowRateModifier",
        catastrophic_charge_rate: "catastrophicChargeWindowRateModifier",
        shatter_damage: "shatterdamageModifier"
      }.freeze

      # The filter is stored as how much inert material it screens out, and
      # reads the other way round from every other modifier: a filter of 30 is
      # 30 % less inert material, which is how the game describes it.
      private def extract_mining_modifiers(modifiers, filter_params)
        values = MINING_MODIFIERS.transform_values do |key|
          modifiers&.dig(key, "FloatModifierMultiplicative", "value")&.to_f
        end

        filter = filter_params&.dig("filterModifier", "FloatModifierMultiplicative", "value")&.to_f
        values[:inert_materials] = -filter if filter

        values.compact.reject { |_, value| value.zero? }.presence
      end

      # A module either sits in its slot for good (passive) or is fired off for
      # a few seconds at a time, a set number of times (active). What it does
      # to the laser's two beams is a multiplier per fire action, kept as the
      # percent change the game prints.
      private def extract_mining_module_data(values)
        params = values.dig("Components", "EntityComponentAttachableModifierParams")
        return if params.blank?

        mining = Array.wrap(params.dig("modifiers", "ItemMiningModifierParams")).first
        weapon_modifiers = Array.wrap(params.dig("modifiers", "ItemWeaponModifiersParams"))
        power_change = ->(index) {
          modifier = weapon_modifiers.find { |entry| entry["fireActionIndex"].to_s == index.to_s }
          multiplier = modifier&.dig("weaponModifier", "weaponStats", "damageMultiplier")&.to_f
          ((multiplier - 1) * 100).round(2).nonzero? if multiplier
        }
        active = params["activationMethod"] == "ActivateOnDemand"

        data = {
          fracture_power: power_change.call(0),
          extraction_power: power_change.call(1),
          modifiers: extract_mining_modifiers(
            mining&.dig("MiningLaserModifier"),
            params.dig("modifiers", "MiningFilterItemModifierParams", "filterParams")
          )
        }.compact
        return if data.empty?

        data.merge(
          mining_module: true,
          activation: active ? "active" : "passive",
          charges: (params["charges"]&.to_i&.nonzero? if active),
          duration: (mining&.dig("modifierLifetime", "ItemModifierTimedLife", "lifetime")&.to_f if active)
        ).compact
      end
    end
  end
end
