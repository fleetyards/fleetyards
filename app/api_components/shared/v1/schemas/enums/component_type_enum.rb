# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ComponentTypeEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: [
              "Seat", "Door", "MainThruster", "Armor", "WeaponDefensive", "ManneuverThruster",
              "CargoGrid", "Cargo", "EMP", "Paints", "TurretBase", "ToolArm", "Turret", "Misc",
              "Module", "ControlPanel", "WeaponGun", "Container", "TractorBeam", "UtilityTurret",
              "TowingBeam", "MissileController", "Lightgroup", "Battery",
              "CapacitorAssignmentController", "CommsController", "CoolerController",
              "DoorController", "EnergyController", "FlightController", "MiningController",
              "BombLauncher", "Bomb", "FuelController", "SalvageController", "ShieldController",
              "TargetSelector", "WeaponController", "WheeledController", "Cooler",
              "DockingAnimator", "Button", "Sensor", "Usable", "ExternalFuelTank", "FuelTank",
              "WeaponMining", "SalvageHead", "JumpDrive", "FuelIntake", "MiningModifier", "Missile",
              "AttachedPart", "LifeSupportGenerator", "SpaceMine", "MissileLauncher",
              "DockingCollar", "PowerPlant", "QuantumFuelTank", "QuantumInterdictionGenerator",
              "QuantumDrive", "Relay", "Radar", "Scanner", "SalvageFillerStation", "Shield",
              "SeatDashboard", "Display", "SelfDestruct", "WeaponAttachment", "SalvageFieldEmitter",
              "SalvageFieldSupporter", "SalvageInternalStorage"
            ]
          })
        end
      end
    end
  end
end
