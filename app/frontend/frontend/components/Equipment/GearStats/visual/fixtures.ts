import { type EquipmentStats } from "@/services/fyApi";

// Read from the 4.10.2-live game files by the equipment parser, so the demo
// shows the shapes and figures the API serves.
export const GEAR = [
  {
    key: "behr_rifle_ballistic_01",
    name: "P4-AR Rifle",
    stats: {
      fireModes: [
        {
          name: "Rapid",
          label: "Auto",
          kind: "rapid",
          fireRate: 810.0,
          ammoCost: 1,
          spread: {
            min: 0.18,
            max: 5.0,
            firstAttack: 1.35,
            attack: 1.25,
            decay: 6.5,
          },
          alpha: 12.0,
          dps: 162.0,
        },
        {
          name: "Single",
          label: "Semi",
          kind: "single",
          fireRate: 810.0,
          ammoCost: 1,
          spread: {
            min: 0.15,
            max: 1.89,
            firstAttack: 1.45,
            attack: 1.35,
            decay: 4.0,
          },
          alpha: 12.0,
          dps: 162.0,
        },
      ],
      ammo: {
        damage: {
          physical: 12.0,
        },
        damageDrop: {
          minDistance: 40.0,
          perMeter: {
            physical: 0.05,
          },
          minDamage: {
            physical: 10.0,
          },
        },
        speed: 550.0,
        lifetime: 2.0,
        range: 1100.0,
        penetration: {
          maxThickness: 5000.0,
          nearRadius: 0.5,
          farRadius: 5.0,
        },
      },
      magazine: {
        size: 40,
        reserve: 3,
      },
    },
  },
  {
    key: "klwe_rifle_energy_01",
    name: "Gallant Rifle",
    stats: {
      fireModes: [
        {
          name: "Burst",
          label: "Burst",
          kind: "burst",
          fireRate: 900.0,
          shots: 3,
          cooldown: 0.25,
          ammoCost: 1,
          heatPerShot: 2.8,
          spread: {
            min: 0.05,
            max: 2.41,
            firstAttack: 1.21,
            attack: 1.03,
            decay: 5.0,
          },
          alpha: 21.0,
          dps: 140.0,
          timeToOverheat: 5.36,
          shotsToOverheat: 35,
        },
        {
          name: "Burst",
          label: "Burst",
          kind: "burst",
          fireRate: 825.0,
          shots: 5,
          cooldown: 0.35,
          ammoCost: 1,
          heatPerShot: 4.0,
          spread: {
            min: 0.05,
            max: 2.41,
            firstAttack: 1.21,
            attack: 1.03,
            decay: 5.0,
          },
          alpha: 21.0,
          dps: 147.13,
          timeToOverheat: 3.57,
          shotsToOverheat: 25,
        },
      ],
      ammo: {
        damage: {
          energy: 21.0,
        },
        speed: 1200.0,
        lifetime: 4.0,
        range: 4800.0,
        penetration: {
          maxThickness: 0.3,
          nearRadius: 0.5,
          farRadius: 5.0,
        },
      },
      magazine: {
        size: 45,
        reserve: 3,
      },
      heat: {
        overheatTemperature: 100.0,
        coolingPerSecond: 3.0,
        coolingDelay: 1.0,
      },
    },
  },
  {
    key: "apar_special_ballistic_01",
    name: "Scourge Railgun",
    stats: {
      fireModes: [
        {
          name: "Charge",
          label: "Charge",
          kind: "charged",
          fireRate: 70.0,
          ammoCost: 1,
          spread: {
            min: 0.0,
            max: 0.0,
            firstAttack: 0.0,
            attack: 0.0,
            decay: 0.0,
          },
          alpha: 6060.0,
          dps: 2121.0,
          charge: {
            time: 2.0,
            overchargeTime: 3.0,
            overchargedTime: 1.0,
            cooldown: 0.5,
            damageMultiplier: 300.0,
            projectileSpeedMultiplier: 50.0,
            partial: false,
            uncharged: {
              alpha: 80.0,
              dps: 93.33,
            },
          },
        },
      ],
      ammo: {
        damage: {
          physical: 20.0,
        },
        damageDrop: {
          minDamage: {
            physical: 2.0,
          },
        },
        speed: 50.0,
        lifetime: 4.0,
        range: 200.0,
        penetration: {
          maxThickness: 2.5,
          nearRadius: 1.61,
          farRadius: 2.01,
        },
        explosion: {
          damage: {
            physical: 60.0,
          },
          minRadius: 5.0,
          maxRadius: 8.0,
          pressure: 10.0,
        },
      },
      magazine: {
        size: 5,
        reserve: 3,
      },
    },
  },
  {
    key: "hdgw_rifle_ballistic_01",
    name: "Arlington Rifle",
    stats: {
      fireModes: [
        {
          name: "Slug",
          label: "Semi",
          kind: "single",
          fireRate: 85.0,
          ammoCost: 1,
          heatPerShot: 10.0,
          spread: {
            min: 0.0,
            max: 1.0,
            firstAttack: 1.0,
            attack: 1.0,
            decay: 3.0,
          },
          alpha: 80.0,
          dps: 113.33,
        },
        {
          name: "Single",
          label: "Semi",
          kind: "single",
          fireRate: 85.0,
          pellets: 8,
          ammoCost: 1,
          heatPerShot: 8.5,
          spread: {
            min: 2.0,
            max: 4.0,
            firstAttack: 2.0,
            attack: 1.0,
            decay: 1.5,
          },
          alpha: 100.0,
          dps: 141.67,
        },
      ],
      ammo: {
        damage: {
          physical: 80.0,
        },
        damageDrop: {
          minDistance: 50.0,
          perMeter: {
            physical: 0.1,
          },
          minDamage: {
            physical: 35.0,
          },
        },
        speed: 550.0,
        lifetime: 2.0,
        range: 1100.0,
        penetration: {
          maxThickness: 5000.0,
          nearRadius: 0.5,
          farRadius: 5.0,
        },
      },
      secondaryAmmo: {
        damage: {
          energy: 12.5,
        },
        speed: 300.0,
        lifetime: 2.0,
        range: 600.0,
        penetration: {
          maxThickness: 20.0,
          nearRadius: 0.5,
          farRadius: 5.0,
        },
      },
      magazine: {
        size: 20,
        reserve: 3,
      },
    },
  },
  {
    key: "volt_rifle_energy_01",
    name: "Parallax Energy Assault Rifle",
    stats: {
      fireModes: [
        {
          name: "RapidBeam",
          kind: "rapid",
          fireRate: 600.0,
          ammoCost: 1,
          heatPerShot: 3.5,
          spread: {
            min: 0.5,
            max: 3.0,
            firstAttack: 0.5,
            attack: 0.25,
            decay: 0.4,
          },
          alpha: 21.0,
          dps: 210.0,
          timeToOverheat: 2.86,
          shotsToOverheat: 28,
        },
        {
          name: "RapidBeam",
          condition: {
            heatLevel: 0.4,
            comparison: "greater_or_equal",
          },
          kind: "beam",
          damagePerSecond: {
            energy: 210.0,
            distortion: 50.0,
          },
          fullDamageRange: 65.0,
          zeroDamageRange: 65.0,
          heatPerSecond: 17.0,
          chargeUpTime: 0.1,
          spread: {
            min: 0.5,
            max: 3.0,
            firstAttack: 0.5,
            attack: 0.25,
            decay: 0.5,
          },
          dps: 260.0,
          timeToOverheat: 5.88,
        },
      ],
      ammo: {
        damage: {
          energy: 13.0,
          distortion: 5.0,
          stun: 3.0,
        },
        damageDrop: {
          minDistance: 200.0,
          perMeter: {
            energy: 0.01,
            distortion: 0.01,
            stun: 0.01,
          },
          minDamage: {
            physical: 10.0,
            energy: 10.0,
            distortion: 5.0,
            stun: 6.0,
          },
        },
        speed: 600.0,
        lifetime: 2.0,
        range: 1200.0,
        penetration: {
          maxThickness: 0.5,
          nearRadius: 0.5,
          farRadius: 5.0,
        },
      },
      magazine: {
        size: 80,
        reserve: 3,
      },
      heat: {
        overheatTemperature: 100.0,
        coolingPerSecond: 25.0,
        coolingDelay: 0.2,
      },
    },
  },
  {
    key: "crlf_medgun_01",
    name: "ParaMed Medical Device",
    stats: {
      toolActions: [
        {
          name: "Heal",
          kind: "heal",
          target: "target",
          range: 2.5,
          sensorRange: 20.0,
          doseRate: 10.0,
          ammoPerDose: 1.0,
        },
        {
          name: "SelfHeal",
          kind: "heal",
          target: "self",
          range: 1.5,
          sensorRange: 20.0,
          doseRate: 10.0,
          ammoPerDose: 1.0,
        },
      ],
      magazine: {
        size: 200,
        reserve: 3,
      },
    },
  },
  {
    key: "grin_multitool_01",
    name: "Pyro RYT Multi-Tool",
    stats: {
      toolActions: [
        {
          name: "Salvage",
          label: "Salvage",
          kind: "salvage",
          range: 5.0,
          healthRate: 310.0,
          damageMapRate: 10.0,
          materialEfficiency: 0.8,
          healthToAmmoRatio: 2.0,
          rampUpTime: 4.0,
        },
        {
          name: "Heal",
          label: "Healing",
          kind: "heal",
          target: "target",
          range: 1.5,
          sensorRange: 20.0,
          doseRate: 8.0,
          ammoPerDose: 1.0,
        },
        {
          name: "Detach",
          label: "Tractor",
          kind: "tractor",
          minForce: 100000.0,
          maxForce: 260000.0,
          minDistance: 0.1,
          maxDistance: 25.0,
          fullStrengthDistance: 10.0,
          maxAngle: 60.0,
          maxVolume: 800.0,
          maxSpeed: 70.0,
        },
        {
          name: "Mining beam and scanning",
          label: "Mining",
          kind: "mining",
          power: 0.1,
          range: 10.0,
          optimalRange: 10.0,
          chargeUpTime: 0.1,
        },
        {
          name: "Repair",
          label: "Repair",
          kind: "repair",
          range: 5.0,
          healthRate: 95.0,
          damageMapRate: 10.0,
          materialEfficiency: 1.0,
          healthToAmmoRatio: 0.08,
          rampUpTime: 0.5,
        },
        {
          name: "TractorBeam",
          label: "Tractor",
          kind: "tractor",
          minForce: 500.0,
          maxForce: 257500.0,
          minDistance: 0.5,
          maxDistance: 150.0,
          fullStrengthDistance: 3.0,
          maxAngle: 40.0,
          maxVolume: 20.0,
          maxSpeed: 5.5,
        },
      ],
      magazine: {
        size: 100,
        reserve: 3,
      },
    },
  },
  {
    key: "behr_gren_frag_01",
    name: "MK-4 Frag Grenade",
    stats: {
      explosion: {
        damage: {
          physical: 120.0,
        },
        minRadius: 4.0,
        maxRadius: 5.5,
        pressure: 280.0,
        fuse: 5.0,
      },
    },
  },
  {
    key: "behr_ltp_kinetic_01",
    name: "ADO-5 Laser Mine",
    stats: {
      explosion: {
        damage: {
          physical: 210.0,
        },
        minRadius: 0.5,
        maxRadius: 5.0,
        pressure: 200.0,
      },
      mine: {
        trigger: "laser",
        length: 2.0,
      },
    },
  },
  {
    key: "mining_gadget_thcn_boremax",
    name: "BoreMax",
    stats: {
      mining: {
        modifiers: {
          instability: -70.0,
          resistance: 10.0,
          clusterFactor: 30.0,
        },
      },
    },
  },
  {
    key: "arma_barrel_comp_s1",
    name: "Sion Compensator1",
    stats: {
      modifier: {
        soundRadius: 1.2,
        recoil: {
          yaw: 0.8,
          pitch: 0.8,
        },
      },
    },
  },
  {
    key: "banu_melee_01",
    name: "Njakte Knife",
    stats: {
      melee: {
        attacks: [
          {
            category: "blade_slash",
            damage: {
              physical: 30.0,
            },
            impulse: 20.0,
          },
          {
            category: "blade_stab",
            damage: {
              physical: 30.0,
            },
            impulse: 20.0,
          },
        ],
      },
    },
  },
  {
    key: "crlf_consumable_healing_01",
    name: "MedPen (Hemozal)",
    stats: {
      consumable: {
        volume: 30.0,
        effects: [
          {
            kind: "health",
            amount: 112.5,
          },
          {
            kind: "status",
            stat: "blood_drug_level",
            amount: 30.0,
          },
        ],
      },
    },
  },
] as unknown as {
  key: string;
  name: string;
  stats: EquipmentStats;
}[];
