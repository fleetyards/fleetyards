module ScData
  class Parser
    attr_accessor :base_path, :export_path, :path, :translations, :manufacturers, :cargogrids

    FOUNDRY_PATH = "Data/Libs/Foundry/Records"

    SCU_DIMENSIONS = 1.25

    def initialize(base_folder:, version:)
      self.base_path = "#{base_folder}/raw/#{version}"
      self.export_path = "#{base_folder}/parsed/#{version}"
      self.path = "#{base_path}/#{FOUNDRY_PATH}"
      self.translations = parse_translations
      self.manufacturers = parse_manufacturers
      self.cargogrids = parse_cargogrids
    end

    def run
      FileUtils.mkdir_p(export_path) unless File.directory?(export_path)

      items = parse_items

      parse_ships(items)

      parse_vehicles(items)
    end

    private def parse_items
      all_items = []
      %w[ships vehicles].each do |type|
        item_categories.each do |category|
          items = Dir.glob("#{path}/entities/scitem/#{type}/#{category}/**/*.xml").filter_map do |file|
            data = Hash.from_xml(File.read(file))
            key = data.keys.first.split(".").last
            values = data.values.first

            parse_item(key, values, category)
          end

          next if items.blank?

          item_path = "#{export_path}/items/#{type}/#{category}"

          FileUtils.mkdir_p(item_path) unless File.directory?(item_path)

          items.each do |item|
            File.write("#{item_path}/#{item[:key].downcase}.json", JSON.pretty_generate(item))
          end

          all_items += items
        end
      end

      all_items
    end

    private def parse_item(key, values, category)
      return unless values.dig("Components").present?
      return if filter_item_keys.any? { |filter| key.downcase.include?(filter) }

      item = {
        key:,
        ref: values.dig("__ref"),
        category: category,
        type: values.dig("Components", "SAttachableComponentParams", "AttachDef", "Type"),
        sub_type: values.dig("Components", "SAttachableComponentParams", "AttachDef", "SubType"),
        size: values.dig("Components", "SAttachableComponentParams", "AttachDef", "Size"),
        grade: values.dig("Components", "SAttachableComponentParams", "AttachDef", "Grade"),
        manufacturer: find_manufacturer(values.dig("Components", "SAttachableComponentParams", "AttachDef", "Manufacturer")),
        name: translate(values.dig("Components", "SAttachableComponentParams", "AttachDef", "Localization", "Name")),
        short_name: translate(values.dig("Components", "SAttachableComponentParams", "AttachDef", "Localization", "ShortName")),
        description: translate(values.dig("Components", "SAttachableComponentParams", "AttachDef", "Localization", "Description")),
        inventory_consumption: {
          micro_scu: values.dig("Components", "SAttachableComponentParams", "AttachDef", "inventoryOccupancyVolume", "SMicroCargoUnit", "microSCU").to_f,
          dimensions: {
            x: values.dig("Components", "SAttachableComponentParams", "AttachDef", "inventoryOccupancyDimensions", "x").to_f,
            y: values.dig("Components", "SAttachableComponentParams", "AttachDef", "inventoryOccupancyDimensions", "y").to_f,
            z: values.dig("Components", "SAttachableComponentParams", "AttachDef", "inventoryOccupancyDimensions", "z").to_f
          }
        }
      }

      ports = values.dig("Components", "SItemPortContainerComponentParams", "Ports", "SItemPortDef")
      if ports.present? && !ports.is_a?(Array)
        ports = [ports]
      end
      if ports.present?
        ports = ports.filter_map do |port|
          key = port.dig("Name")

          if key.include?("lightning")
            next
          end

          types = port.dig("Types", "SItemPortDefTypes")
          if types.present? && !types.is_a?(Array)
            types = [types]
          elsif types.blank?
            types = []
          end

          {
            key:,
            min_size: port.dig("MinSize"),
            max_size: port.dig("MaxSize"),
            types: types.map do |type|
              type.dig("Type")
            end
          }
        end

        if ports.present?
          item[:ports] = ports
        end
      end

      if values.dig("Components", "SInventoryParams")
        capacity = values.dig("Components", "SInventoryParams", "capacity")
        storage = if capacity.dig("SStandardCargoUnit").present?
          capacity.dig("SStandardCargoUnit", "standardCargoUnits").to_f
        elsif capacity.dig("SMicroCargoUnit").present?
          capacity.dig("SMicroCargoUnit", "microSCU").to_f**-6
        elsif capacity.dig("SCentiCargoUnit").present?
          capacity.dig("SCentiCargoUnit", "centiSCU").to_f**-2
        end

        if storage.present?
          item[:inventory] = {
            storage:
          }
        end
      end

      if values.dig("Components", "SCItemInventoryContainerComponentParams")
        inventory_container = cargogrids.find do |inventory|
          inventory[:ref] == values.dig("Components", "SCItemInventoryContainerComponentParams", "containerParams")
        end
        if inventory_container.present?
          item[:inventory_container] = inventory_container
        end
      end

      if values.dig("Components", "SAmmoContainerComponentParams")
        item[:ammo] = {
          max_ammo_count: values.dig("Components", "SAmmoContainerComponentParams", "maxAmmoCount").to_f,
          initial_ammo_count: values.dig("Components", "SAmmoContainerComponentParams", "initialAmmoCount").to_f,
          max_restock_count: values.dig("Components", "SAmmoContainerComponentParams", "maxRestockCount").to_f
        }
      end

      if values.dig("Components", "EntityComponentPowerConnection")
        item[:power] = {
          power_base: values.dig("Components", "EntityComponentPowerConnection", "PowerBase").to_f,
          power_draw: values.dig("Components", "EntityComponentPowerConnection", "PowerDraw").to_f,
          time_to_reach_draw_request: values.dig("Components", "EntityComponentPowerConnection", "TimeToReachDrawRequest").to_f,
          safeguard_priority: values.dig("Components", "EntityComponentPowerConnection", "SafeguardPriority").to_f,
          displayed_in_powered_item_list: values.dig("Components", "EntityComponentPowerConnection", "DisplayedInPoweredItemList").to_f,
          is_throttleable: values.dig("Components", "EntityComponentPowerConnection", "IsThrottleable").to_f,
          is_overclockable: values.dig("Components", "EntityComponentPowerConnection", "IsOverclockable").to_f,
          overclock_threshold_min: values.dig("Components", "EntityComponentPowerConnection", "OverclockThresholdMin").to_f,
          overclock_threshold_max: values.dig("Components", "EntityComponentPowerConnection", "OverclockThresholdMax").to_f,
          overpower_performance: values.dig("Components", "EntityComponentPowerConnection", "OverpowerPerformance").to_f,
          overclock_performance: values.dig("Components", "EntityComponentPowerConnection", "OverclockPerformance").to_f,
          power_to_em: values.dig("Components", "EntityComponentPowerConnection", "PowerToEM").to_f,
          decay_rate_of_em: values.dig("Components", "EntityComponentPowerConnection", "DecayRateOfEM").to_f
        }
      end

      if values.dig("Components", "SCItemCoolerParams")
        item[:type_data] = {
          cooling_rate: values.dig("Components", "SCItemCoolerParams", "CoolingRate").to_f
        }
      end

      if values.dig("Components", "SCItemFuelTankParams")
        item[:type_data] = {
          fill_rate: values.dig("Components", "SCItemFuelTankParams", "fillRate").to_f,
          drain_rate: values.dig("Components", "SCItemFuelTankParams", "drainRate").to_f,
          capacity: values.dig("Components", "SCItemFuelTankParams", "capacity").to_f
        }
      end

      if values.dig("Components", "SCItemFuelIntakeParams")
        item[:type_data] = {
          fuel_push_rate: values.dig("Components", "SCItemFuelIntakeParams", "fuelPushRate").to_f,
          minimum_rate: values.dig("Components", "SCItemFuelIntakeParams", "minimumRate").to_f
        }
      end

      if values.dig("Components", "SCItemQuantumDriveParams")
        item[:type_data] = {
          quantum_fuel_requirement: values.dig("Components", "SCItemQuantumDriveParams", "quantumFuelRequirement").to_f,
          jump_range: values.dig("Components", "SCItemQuantumDriveParams", "jumpRange").to_f,
          disconnect_range: values.dig("Components", "SCItemQuantumDriveParams", "disconnectRange").to_f,
          drive_speed: values.dig("Components", "SCItemQuantumDriveParams", "params", "driveSpeed").to_f,
          cooldown_time: values.dig("Components", "SCItemQuantumDriveParams", "params", "cooldownTime").to_f,
          stage_one_accel_rate: values.dig("Components", "SCItemQuantumDriveParams", "params", "stageOneAccelRate").to_f,
          stage_two_accel_rate: values.dig("Components", "SCItemQuantumDriveParams", "params", "stageTwoAccelRate").to_f,
          engage_speed: values.dig("Components", "SCItemQuantumDriveParams", "params", "engageSpeed").to_f,
          calibration_rate: values.dig("Components", "SCItemQuantumDriveParams", "params", "calibrationRate").to_f,
          min_calibration_requirement: values.dig("Components", "SCItemQuantumDriveParams", "params", "minCalibrationRequirement").to_f,
          max_calibration_requirement: values.dig("Components", "SCItemQuantumDriveParams", "params", "maxCalibrationRequirement").to_f,
          calibration_process_angle_limit: values.dig("Components", "SCItemQuantumDriveParams", "params", "calibrationProcessAngleLimit").to_f,
          calibration_warning_angle_limit: values.dig("Components", "SCItemQuantumDriveParams", "params", "calibrationWarningAngleLimit").to_f,
          calibration_delay_in_seconds: values.dig("Components", "SCItemQuantumDriveParams", "params", "calibrationDelayInSeconds").to_f,
          spool_up_time: values.dig("Components", "SCItemQuantumDriveParams", "params", "spoolUpTime").to_f,
          spline_jump_params: {
            drive_speed: values.dig("Components", "SCItemQuantumDriveParams", "splineJumpParams", "driveSpeed").to_f,
            cooldown_time: values.dig("Components", "SCItemQuantumDriveParams", "splineJumpParams", "cooldownTime").to_f,
            stage_one_accel_rate: values.dig("Components", "SCItemQuantumDriveParams", "splineJumpParams", "stageOneAccelRate").to_f,
            stage_two_accel_rate: values.dig("Components", "SCItemQuantumDriveParams", "splineJumpParams", "stageTwoAccelRate").to_f,
            engage_speed: values.dig("Components", "SCItemQuantumDriveParams", "splineJumpParams", "engageSpeed").to_f,
            calibration_rate: values.dig("Components", "SCItemQuantumDriveParams", "splineJumpParams", "calibrationRate").to_f,
            min_calibration_requirement: values.dig("Components", "SCItemQuantumDriveParams", "splineJumpParams", "minCalibrationRequirement").to_f,
            max_calibration_requirement: values.dig("Components", "SCItemQuantumDriveParams", "splineJumpParams", "maxCalibrationRequirement").to_f,
            calibration_process_angle_limit: values.dig("Components", "SCItemQuantumDriveParams", "splineJumpParams", "calibrationProcessAngleLimit").to_f,
            calibration_warning_angle_limit: values.dig("Components", "SCItemQuantumDriveParams", "splineJumpParams", "calibrationWarningAngleLimit").to_f,
            calibration_delay_in_seconds: values.dig("Components", "SCItemQuantumDriveParams", "splineJumpParams", "calibrationDelayInSeconds").to_f,
            spool_up_time: values.dig("Components", "SCItemQuantumDriveParams", "splineJumpParams", "spoolUpTime").to_f
          },
          quantum_boost_params: {
            max_boost_speed: values.dig("Components", "SCItemQuantumDriveParams", "quantumBoostParams", "maxBoostSpeed").to_f,
            time_to_max_boost_speed: values.dig("Components", "SCItemQuantumDriveParams", "quantumBoostParams", "timeToMaxBoostSpeed").to_f,
            boost_use_time: values.dig("Components", "SCItemQuantumDriveParams", "quantumBoostParams", "boostUseTime").to_f,
            boost_recharge_time: values.dig("Components", "SCItemQuantumDriveParams", "quantumBoostParams", "boostRechargeTime").to_f,
            stop_time: values.dig("Components", "SCItemQuantumDriveParams", "quantumBoostParams", "stopTime").to_f,
            min_jump_distance: values.dig("Components", "SCItemQuantumDriveParams", "quantumBoostParams", "minJumpDistance").to_f,
            ifcs_handover_down_time: values.dig("Components", "SCItemQuantumDriveParams", "quantumBoostParams", "ifcsHandoverDownTime").to_f,
            ifcs_handover_respool_time: values.dig("Components", "SCItemQuantumDriveParams", "quantumBoostParams", "ifcsHandoverRespoolTime").to_f
          }
        }

      end

      if values.dig("Components", "SCItemRadarComponentParams")
        item[:type_data] = {
          signature_detection: values.dig("Components", "SCItemRadarComponentParams", "signatureDetection", "SCItemRadarSignatureDetection").map do |signature|
            {
              sensitivity: signature.dig("sensitivity").to_f,
              piercing: signature.dig("piercing").to_f,
              permit_active_detection: signature.dig("permitActiveDetection").to_f,
              permit_passive_detection: signature.dig("permitPassiveDetection").to_f
            }
          end,
          ping_properties: {
            cooldown_time: values.dig("Components", "SCItemRadarComponentParams", "pingProperties", "cooldownTime").to_f
          },
          sensitivityModifiers: {
            sensitivityAddition: values.dig("Components", "SCItemRadarComponentParams", "sensitivityModifiers", "SCItemRadarSensitivityModifier", "sensitivityAddition").to_f
          }
        }
      end

      if values.dig("Components", "SSCItemSelfDestructComponentParams")
        item[:type_data] = {
          damage: values.dig("Components", "SSCItemSelfDestructComponentParams", "damage"),
          min_radius: values.dig("Components", "SSCItemSelfDestructComponentParams", "minRadius"),
          radius: values.dig("Components", "SSCItemSelfDestructComponentParams", "radius"),
          min_phys_radius: values.dig("Components", "SSCItemSelfDestructComponentParams", "minPhysRadius"),
          phys_radius: values.dig("Components", "SSCItemSelfDestructComponentParams", "physRadius"),
          time: values.dig("Components", "SSCItemSelfDestructComponentParams", "time")
        }
      end

      if values.dig("Components", "SCItemShieldGeneratorParams")
        item[:type_data] = {
          max_health: values.dig("Components", "SCItemShieldGeneratorParams", "MaxShieldHealth").to_f,
          max_regen: values.dig("Components", "SCItemShieldGeneratorParams", "MaxShieldRegen").to_f,
          decay_ratio: values.dig("Components", "SCItemShieldGeneratorParams", "DecayRatio").to_f,
          reserve_pool_initial_health_ratio: values.dig("Components", "SCItemShieldGeneratorParams", "ReservePoolInitialHealthRatio").to_f,
          reserve_pool_max_health_ratio: values.dig("Components", "SCItemShieldGeneratorParams", "ReservePoolMaxHealthRatio").to_f,
          reserve_pool_regen_rate_ratio: values.dig("Components", "SCItemShieldGeneratorParams", "ReservePoolRegenRateRatio").to_f,
          reserve_pool_drain_rate_ratio: values.dig("Components", "SCItemShieldGeneratorParams", "ReservePoolDrainRateRatio").to_f,
          downed_regen_delay: values.dig("Components", "SCItemShieldGeneratorParams", "DownedRegenDelay").to_f,
          damaged_regen_delay: values.dig("Components", "SCItemShieldGeneratorParams", "DamagedRegenDelay").to_f,
          electrical_charge_damage_resistance: values.dig("Components", "SCItemShieldGeneratorParams", "ElectricalChargeDamageResistance").to_f,
          stun_params: {
            min_alpha_damage_ratio: values.dig("Components", "SCItemShieldGeneratorParams", "stunParams", "minAlphaDamageRatio").to_f,
            max_alpha_damage_ratio: values.dig("Components", "SCItemShieldGeneratorParams", "stunParams", "maxAlphaDamageRatio").to_f,
            min_stun_time: values.dig("Components", "SCItemShieldGeneratorParams", "stunParams", "minStunTime").to_f,
            max_stun_time: values.dig("Components", "SCItemShieldGeneratorParams", "stunParams", "maxStunTime").to_f
          },
          resistance: values.dig("Components", "SCItemShieldGeneratorParams", "ShieldResistance", "SShieldResistance").map do |resistance|
            {
              max: resistance.dig("Max").to_f,
              min: resistance.dig("Min").to_f
            }
          end,
          absorption: values.dig("Components", "SCItemShieldGeneratorParams", "ShieldAbsorption", "SShieldAbsorption").map do |absorption|
            {
              max: absorption.dig("Max").to_f,
              min: absorption.dig("Min").to_f
            }
          end
        }

      end

      if values.dig("Components", "SCItemThrusterParams")
        item[:type_data] = {
          thrust_capacity: values.dig("Components", "SCItemThrusterParams", "thrustCapacity").to_f,
          fuel_burn_rate_per10_k_newton: values.dig("Components", "SCItemThrusterParams", "fuelBurnRatePer10KNewton"),
          thruster_type: values.dig("Components", "SCItemThrusterParams", "thrusterType")
        }
      end

      if values.dig("Components", "SCItemEMPParams")
        item[:type_data] = {
          charge_time: values.dig("Components", "SCItemEMPParams", "chargeTime").to_f,
          distortion_damage: values.dig("Components", "SCItemEMPParams", "distortionDamage").to_f,
          emp_radius: values.dig("Components", "SCItemEMPParams", "empRadius").to_f,
          min_emp_radius: values.dig("Components", "SCItemEMPParams", "minEmpRadius").to_f,
          phys_radius: values.dig("Components", "SCItemEMPParams", "physRadius").to_f,
          min_phys_radius: values.dig("Components", "SCItemEMPParams", "minPhysRadius").to_f,
          pressure: values.dig("Components", "SCItemEMPParams", "pressure").to_f,
          unleash_time: values.dig("Components", "SCItemEMPParams", "unleashTime").to_f,
          cooldown_time: values.dig("Components", "SCItemEMPParams", "cooldownTime").to_f
        }
      end

      if values.dig("Components", "IFCSParams")
        item[:ifcs] = {
          scm_speed: values.dig("Components", "IFCSParams", "scmSpeed").to_f,
          scm_speed_boosted: values.dig("Components", "IFCSParams", "boostSpeedForward").to_f,
          reverse_speed_boosted: values.dig("Components", "IFCSParams", "boostSpeedBackward").to_f,
          max_speed: values.dig("Components", "IFCSParams", "maxSpeed").to_f,
          angular_velocity: {
            pitch: values.dig("Components", "IFCSParams", "maxAngularVelocity", "x").to_f,
            yaw: values.dig("Components", "IFCSParams", "maxAngularVelocity", "z").to_f,
            roll: values.dig("Components", "IFCSParams", "maxAngularVelocity", "y").to_f
          },
          boosted_angular_velocity: {
            pitch: values.dig("Components", "IFCSParams", "maxAngularVelocity", "x").to_f * values.dig("Components", "IFCSParams", "afterburner", "afterburnAngVelocityMultiplier", "x").to_f,
            yaw: values.dig("Components", "IFCSParams", "maxAngularVelocity", "z").to_f * values.dig("Components", "IFCSParams", "afterburner", "afterburnAngVelocityMultiplier", "z").to_f,
            roll: values.dig("Components", "IFCSParams", "maxAngularVelocity", "y").to_f * values.dig("Components", "IFCSParams", "afterburner", "afterburnAngVelocityMultiplier", "y").to_f
          }
        }
      end

      if values.dig("Components", "SCItemQuantumInterdictionGeneratorParams")
        item[:type_data] = {
          base_power_draw_fraction: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "basePowerDrawFraction").to_f,
          pulse_power_fraction: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "pulsePowerFraction").to_f,
          jammer_power_fraction: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "jammerPowerFraction").to_f,
          jammer_settings: {
            jammer_range: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "jammerSettings", "SCItemQuantumJammerParams", "jammerRange").to_f,
            max_power_draw: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "jammerSettings", "SCItemQuantumJammerParams", "maxPowerDraw").to_f,
            green_zone_check_range: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "jammerSettings", "SCItemQuantumJammerParams", "greenZoneCheckRange").to_f
          },
          quantum_interdiction_pulse_settings: {
            charge_time_secs: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "quantumInterdictionPulseSettings", "SCItemQuantumInterdictionPulseParams", "chargeTimeSecs").to_f,
            discharge_time_secs: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "quantumInterdictionPulseSettings", "SCItemQuantumInterdictionPulseParams", "dischargeTimeSecs").to_f,
            cooldown_time_secs: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "quantumInterdictionPulseSettings", "SCItemQuantumInterdictionPulseParams", "cooldownTimeSecs").to_f,
            radius_meters: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "quantumInterdictionPulseSettings", "SCItemQuantumInterdictionPulseParams", "radiusMeters").to_f,
            decrease_charge_rate_time_seconds: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "quantumInterdictionPulseSettings", "SCItemQuantumInterdictionPulseParams", "decreaseChargeRateTimeSeconds").to_f,
            increase_charge_rate_time_seconds: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "quantumInterdictionPulseSettings", "SCItemQuantumInterdictionPulseParams", "increaseChargeRateTimeSeconds").to_f,
            activation_phase_duration_seconds: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "quantumInterdictionPulseSettings", "SCItemQuantumInterdictionPulseParams", "activationPhaseDuration_seconds").to_f,
            disperse_charge_time_seconds: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "quantumInterdictionPulseSettings", "SCItemQuantumInterdictionPulseParams", "disperseChargeTimeSeconds").to_f,
            max_power_draw: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "quantumInterdictionPulseSettings", "SCItemQuantumInterdictionPulseParams", "maxPowerDraw").to_f,
            stop_charging_power_draw_fraction: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "quantumInterdictionPulseSettings", "SCItemQuantumInterdictionPulseParams", "stopChargingPowerDrawFraction").to_f,
            max_charge_rate_power_draw_fraction: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "quantumInterdictionPulseSettings", "SCItemQuantumInterdictionPulseParams", "maxChargeRatePowerDrawFraction").to_f,
            active_power_draw_fraction: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "quantumInterdictionPulseSettings", "SCItemQuantumInterdictionPulseParams", "activePowerDrawFraction").to_f,
            tethering_power_draw_fraction: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "quantumInterdictionPulseSettings", "SCItemQuantumInterdictionPulseParams", "tetheringPowerDrawFraction").to_f,
            green_zone_check_range: values.dig("Components", "SCItemQuantumInterdictionGeneratorParams", "quantumInterdictionPulseSettings", "SCItemQuantumInterdictionPulseParams", "greenZoneCheckRange").to_f
          }
        }
      end

      # if values.dig("Components", "SCItemBombParams")
      #   item[:type_data] = values.dig("Components", "SCItemBombParams")
      # end

      # if values.dig("Components", "SCItemToolArmParams")
      #   item[:type_data] = values.dig("Components", "SCItemToolArmParams")
      # end

      # if values.dig("Components", "SCItemMissileRackParams")
      #   item[:type_data] = values.dig("Components", "SCItemMissileRackParams")
      # end

      # if values.dig("Components", "SCItemWeaponComponentParams")
      #   item[:type_data] = values.dig("Components", "SCItemWeaponComponentParams")
      # end

      # if values.dig("Components", "SCItemVehicleArmorParams")
      #   item[:type_data] = values.dig("Components", "SCItemVehicleArmorParams")
      # end

      # if values.dig("Components", "SCItemTurretParams")
      #   item[:type_data] = values.dig("Components", "SCItemTurretParams")
      # end

      item
    end

    private def item_categories
      %w[
        armor batteries computers missile_racks bombcompartments cooler module powerplant
        quantumdrive quantumenforcementdevice shieldgenerator turret utility weapon_mounts weapons
        lifesupport thrusters radar scanners fueltanks fuel_intakes countermeasures seat relay
        salvagemunching salvagefillerstation selfdestruct paints controller
      ]
    end

    private def parse_translations
      load_ini_file("#{base_path}/Data/Localization/english/global.ini")
    end

    private def parse_manufacturers
      Dir.glob("#{path}/scitemmanufacturer/**/*.xml").filter_map do |file|
        data = Hash.from_xml(File.read(file))
        values = data.values.first

        code = values.dig("Code")

        next if code.blank?

        {
          code:,
          ref: values.dig("__ref"),
          name: translate(values.dig("Localization", "Name")),
          short_name: translate(values.dig("Localization", "ShortName")),
          description: translate(values.dig("Localization", "Description"))
        }
      end
    end

    private def parse_cargogrids
      Dir.glob("#{path}/inventorycontainers/{cargogrid,ships,groundvehicles}/**/*.xml").filter_map do |file|
        data = Hash.from_xml(File.read(file))
        key = data.keys.first.split(".").last
        values = data.values.first

        parse_inventory(key, values)
      end
    end

    private def parse_inventory(key, values)
      type = if values.dig("inventoryType", "InventoryOpenContainerType").present?
        :cargo_grid
      elsif values.dig("inventoryType", "InventoryClosedContainerType").present?
        :personal_storage
      else
        :unknown
      end

      raw_data = {
        key:,
        ref: values.dig("__ref"),
        type:
      }

      if type == :cargo_grid
        if values.dig("interiorDimensions", "x").present?
          x = values.dig("interiorDimensions", "x").to_f
          y = values.dig("interiorDimensions", "y").to_f
          z = values.dig("interiorDimensions", "z").to_f

          raw_data[:dimensions] = extract_dimensions(x, y, z)
        end

        if values.dig("inventoryType", "InventoryOpenContainerType", "minPermittedItemSize", "x").present?
          x = values.dig("inventoryType", "InventoryOpenContainerType", "minPermittedItemSize", "x").to_f
          y = values.dig("inventoryType", "InventoryOpenContainerType", "minPermittedItemSize", "y").to_f
          z = values.dig("inventoryType", "InventoryOpenContainerType", "minPermittedItemSize", "z").to_f

          raw_data[:min_container] = extract_dimensions(x, y, z)
        end

        if values.dig("inventoryType", "InventoryOpenContainerType", "maxPermittedItemSize", "x").present?
          x = values.dig("inventoryType", "InventoryOpenContainerType", "maxPermittedItemSize", "x").to_f
          y = values.dig("inventoryType", "InventoryOpenContainerType", "maxPermittedItemSize", "y").to_f
          z = values.dig("inventoryType", "InventoryOpenContainerType", "maxPermittedItemSize", "z").to_f

          raw_data[:max_container] = extract_dimensions(x, y, z)
        end
      end

      if type == :personal_storage
        capacity = values.dig("inventoryType", "InventoryClosedContainerType", "capacity")
        raw_data[:storage] = if capacity.dig("SStandardCargoUnit").present?
          capacity.dig("SStandardCargoUnit", "standardCargoUnits").to_f
        elsif capacity.dig("SMicroCargoUnit").present?
          capacity.dig("SMicroCargoUnit", "microSCU").to_f**-6
        elsif capacity.dig("SCentiCargoUnit").present?
          capacity.dig("SCentiCargoUnit", "centiSCU").to_f**-2
        end
      end

      raw_data
    end

    private def extract_dimensions(x, y, z)
      {
        x:,
        y:,
        z:,
        scu: (x * y * z) / (SCU_DIMENSIONS * SCU_DIMENSIONS * SCU_DIMENSIONS)
      }
    end

    private def filter_item_keys
      [
        "camera"
      ]
    end

    private def parse_ships(items)
      ships = Dir.glob("#{path}/entities/spaceships/**/*.xml").filter_map do |file|
        data = Hash.from_xml(File.read(file))
        key = data.keys.first.split(".").last
        values = data.values.first

        ports = (values.dig("Components", "SEntityComponentDefaultLoadoutParams", "loadout", "SItemPortLoadoutManualParams", "entries", "SItemPortLoadoutEntryParams") || []).filter_map do |port|
          extract_item_port(port, items)
        end

        {
          key:,
          movement_class: values.dig("Components", "VehicleComponentParams", "movementClass"),
          gravlev: values.dig("Components", "VehicleComponentParams", "isGravlevVehicle"),
          min_crew: values.dig("Components", "VehicleComponentParams", "crewSize"),
          name: translate(values.dig("Components", "VehicleComponentParams", "vehicleName")),
          description: translate(values.dig("Components", "VehicleComponentParams", "vehicleDescription")),
          career: translate(values.dig("Components", "VehicleComponentParams", "vehicleCareer")),
          role: translate(values.dig("Components", "VehicleComponentParams", "vehicleRole")),
          insurance: {
            base_wait_time_minutes: values.dig("StaticEntityClassData", "SEntityInsuranceProperties", "shipInsuranceParams", "baseWaitTimeMinutes"),
            mandatory_wait_time_minutes: values.dig("StaticEntityClassData", "SEntityInsuranceProperties", "shipInsuranceParams", "mandatoryWaitTimeMinutes"),
            base_expediting_fee: values.dig("StaticEntityClassData", "SEntityInsuranceProperties", "shipInsuranceParams", "baseExpeditingFee")
          },
          metrics: {
            x: values.dig("Components", "VehicleComponentParams", "maxBoundingBoxSize", "x").to_f,
            y: values.dig("Components", "VehicleComponentParams", "maxBoundingBoxSize", "y").to_f,
            z: values.dig("Components", "VehicleComponentParams", "maxBoundingBoxSize", "z").to_f
          },
          ports:
        }
      end

      return if ships.blank?

      ships_path = "#{export_path}/ships"

      FileUtils.mkdir_p(ships_path) unless File.directory?(ships_path)

      ships.each do |ship|
        File.write("#{ships_path}/#{ship[:key].downcase}.json", JSON.pretty_generate(ship))
      end
    end

    private def parse_vehicles(items)
      vehicles = Dir.glob("#{path}/entities/groundvehicles/**/*.xml").filter_map do |file|
        data = Hash.from_xml(File.read(file))
        key = data.keys.first.split(".").last
        values = data.values.first || {}

        ports = (values.dig("Components", "SEntityComponentDefaultLoadoutParams", "loadout", "SItemPortLoadoutManualParams", "entries", "SItemPortLoadoutEntryParams") || []).filter_map do |port|
          extract_item_port(port, items)
        end

        insurance = values.dig("StaticEntityClassData", "SEntityInsuranceProperties")

        if insurance.is_a?(Array)
          insurance = insurance.last
        end

        {
          key:,
          movement_class: values.dig("Components", "VehicleComponentParams", "movementClass"),
          gravlev: values.dig("Components", "VehicleComponentParams", "isGravlevVehicle"),
          min_crew: values.dig("Components", "VehicleComponentParams", "crewSize"),
          name: translate(values.dig("Components", "VehicleComponentParams", "vehicleName")),
          description: translate(values.dig("Components", "VehicleComponentParams", "vehicleDescription")),
          career: translate(values.dig("Components", "VehicleComponentParams", "vehicleCareer")),
          role: translate(values.dig("Components", "VehicleComponentParams", "vehicleRole")),
          insurance: {
            base_wait_time_minutes: insurance.dig("shipInsuranceParams", "baseWaitTimeMinutes"),
            mandatory_wait_time_minutes: insurance.dig("shipInsuranceParams", "mandatoryWaitTimeMinutes"),
            base_expediting_fee: insurance.dig("shipInsuranceParams", "baseExpeditingFee")
          },
          metrics: {
            x: values.dig("Components", "VehicleComponentParams", "maxBoundingBoxSize", "x").to_f,
            y: values.dig("Components", "VehicleComponentParams", "maxBoundingBoxSize", "y").to_f,
            z: values.dig("Components", "VehicleComponentParams", "maxBoundingBoxSize", "z").to_f
          },
          ports:
        }
      end

      return if vehicles.blank?

      vehicles_path = "#{export_path}/vehicles"

      FileUtils.mkdir_p(vehicles_path) unless File.directory?(vehicles_path)

      vehicles.each do |vehicle|
        File.write("#{vehicles_path}/#{vehicle[:key].downcase}.json", JSON.pretty_generate(vehicle))
      end
    end

    private def extract_item_port(port, items)
      port_key = port.dig("itemPortName")

      if port_key.include?("animated")
        return
      end

      data = {
        key: port_key
      }

      item = items.find { |item| item[:ref] == port.dig("entityClassReference") || item[:key] == port.dig("entityClassName") }

      if item.present?
        data[:item] = item
      end

      loadout = port.dig("loadout").is_a?(String) ? {} : port.dig("loadout")
      loadout = loadout.dig("SItemPortLoadoutManualParams", "entries", "SItemPortLoadoutEntryParams") || []
      unless loadout.is_a?(Array)
        loadout = [loadout]
      end
      loadout = loadout.filter_map do |entry|
        extract_item_port(entry, items)
      end

      if loadout.present?
        data[:loadout] = loadout
      end

      data
    end

    private def translate(key)
      return nil if key == "@LOC_EMPTY"

      return translations.dig(key.delete("@")) if key.starts_with?("@")

      key
    end

    private def find_manufacturer(ref)
      manufacturers.find do |manufacturer|
        manufacturer[:ref] == ref
      end
    end

    private def load_ini_file(path)
      data = {}

      File.readlines(path).each do |line|
        line = line.chomp

        unless /^\#/.match?(line)
          if /^([^=]+?)\s*=\s*(.*?)\s*$/.match?(line)
            param, val = line.split(/\s*=\s*/, 2)

            var_name = param.to_s.chomp.strip
            val = val.chomp.strip

            data[var_name] = val
          end
        end
      end

      data
    end
  end
end
