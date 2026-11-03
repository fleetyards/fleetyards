import {
  type ComponentWeaponDamage,
  type ComponentWeaponSpread,
  type EquipmentAmmo,
  type EquipmentFireMode,
  type EquipmentStats,
  type EquipmentToolAction,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

export interface GearStatRow {
  label: string;
  value: string;
  // A value too long for one line beside its label -- a dose's effects, a
  // falloff -- goes underneath it instead of being cut off.
  stack?: boolean;
}

export interface GearStatSection {
  key: string;
  title: string;
  rows: GearStatRow[];
}

const DAMAGE_TYPES = [
  "physical",
  "energy",
  "distortion",
  "thermal",
  "biochemical",
  "stun",
] as const;

// Each figure a tool action can carry, the unit it is shown in, and how it is
// scaled to that unit. Forces stay in newtons: the newton unit shows them in kN.
const TOOL_FIELDS: {
  key: keyof EquipmentToolAction;
  units?: string;
  scale?: number;
}[] = [
  { key: "range", units: "distance" },
  { key: "optimalRange", units: "distance" },
  { key: "sensorRange", units: "distance" },
  { key: "doseRate" },
  { key: "power" },
  { key: "minForce", units: "newton" },
  { key: "maxForce", units: "newton" },
  { key: "minDistance", units: "distance" },
  { key: "maxDistance", units: "distance" },
  { key: "fullStrengthDistance", units: "distance" },
  { key: "maxAngle", units: "degrees" },
  { key: "maxVolume", units: "cargo" },
  { key: "maxSpeed", units: "speed" },
  { key: "healthRate" },
  { key: "damageMapRate" },
  { key: "materialEfficiency", units: "percent", scale: 100 },
  { key: "rampUpTime", units: "seconds" },
  { key: "chargeUpTime", units: "seconds" },
  { key: "resourceRate" },
  { key: "minPrime" },
  { key: "maxPrime" },
  { key: "primeTime", units: "seconds" },
  { key: "overloadDuration", units: "seconds" },
  { key: "coneAngle", units: "degrees" },
  { key: "maxRadius", units: "distance" },
];

/**
 * What a piece of gear does, as the cards its page shows: one per fire mode
 * and per tool action, then one for each other part the game files describe.
 * A figure the record does not carry is left out, and so is a card left with
 * nothing in it.
 */
// "TractorBeam" reads as "Tractor Beam".
const humanize = (name?: string) =>
  name?.replace(/([a-z])([A-Z])/g, "$1 $2").trim() || undefined;

export const useGearStatSections = (
  stats: MaybeRefOrGetter<EquipmentStats | null | undefined>,
) => {
  const { t, toNumber } = useI18n();

  const label = (key: string) => t(`labels.equipment.gear.fields.${key}`);

  const figure = (value: number | null | undefined, units = "") => {
    if (value == null) return undefined;
    if (value === 0) return units ? t(`number.${units}`, { count: 0 }) : "0";

    return String(toNumber(value, units));
  };

  // Spread and a round's falloff per metre live below the one decimal the
  // stat formatter keeps -- 0.05°, 0.0137 a metre -- so they keep three
  // significant figures instead.
  const precise = (value: number | null | undefined, units = "") => {
    if (value == null) return undefined;

    const count = String(Number(value.toPrecision(3))).replace(
      ".",
      t("number.format.separator"),
    );

    return units
      ? // i18n-js types `count` as a number; the unit strings only interpolate it.
        t(`number.${units}`, { count } as unknown as { count: number })
      : String(count);
  };

  const damage = (
    map?: ComponentWeaponDamage | null,
    format: (value: number | null | undefined) => string | undefined = figure,
  ) => {
    if (!map) return undefined;

    const parts = DAMAGE_TYPES.filter((type) => map[type] != null).map(
      (type) =>
        `${format(map[type])} ${t(`labels.equipment.gear.damageTypes.${type}`)}`,
    );

    return parts.length ? parts.join(" · ") : undefined;
  };

  // A railgun's charged shot states a spread of nothing at all.
  const spread = (value?: ComponentWeaponSpread | null) => {
    if (value?.min == null || !value.max) return undefined;

    return `${precise(value.min, "degrees")} – ${precise(value.max, "degrees")}`;
  };

  // A multiplier reads as the change it makes: 0.8 is 20 % less.
  const change = (value?: number | null) => {
    if (value == null) return undefined;

    const percent = Math.round((value - 1) * 1000) / 10;

    return `${percent > 0 ? "+" : ""}${figure(percent, "percent")}`;
  };

  // The mining modifiers are stored as the percent change already.
  const percentChange = (value?: number | null) => {
    if (value == null) return undefined;

    return `${value > 0 ? "+" : ""}${figure(value, "percent")}`;
  };

  const row = (
    key: string,
    value: string | undefined,
    stack = false,
  ): GearStatRow[] =>
    value
      ? [
          {
            label: label(key),
            value,
            // Damage of several types runs too long to share a line.
            ...(stack || value.includes(" · ") ? { stack: true } : {}),
          },
        ]
      : [];

  const modeTitle = (mode: EquipmentFireMode) => {
    const name =
      mode.label || t(`labels.equipment.gear.fireModes.${mode.kind}`);
    const heat = mode.condition?.heatLevel;

    if (heat == null) return name;

    return t("labels.equipment.gear.condition", {
      mode: name,
      percent: figure(heat * 100, "percent"),
    });
  };

  const fireMode = (mode: EquipmentFireMode, index: number) => ({
    key: `fire-mode-${index}`,
    title: modeTitle(mode),
    rows: [
      ...row("alpha", figure(mode.alpha, "damage")),
      ...row("dps", figure(mode.dps, "dps")),
      ...row("damagePerSecond", damage(mode.damagePerSecond)),
      ...row("fireRate", figure(mode.fireRate, "rateOfFire")),
      ...row("shots", figure(mode.shots)),
      ...row("cooldown", figure(mode.cooldown, "seconds")),
      ...row("pellets", figure(mode.pellets)),
      ...row("chargeTime", figure(mode.charge?.time, "seconds")),
      ...row(
        "fullChargeDamage",
        mode.charge?.damageMultiplier != null
          ? `×${figure(mode.charge.damageMultiplier)}`
          : undefined,
      ),
      ...row("unchargedAlpha", figure(mode.charge?.uncharged?.alpha, "damage")),
      ...row("unchargedDps", figure(mode.charge?.uncharged?.dps, "dps")),
      ...row("fullDamageRange", figure(mode.fullDamageRange, "distance")),
      ...row("zeroDamageRange", figure(mode.zeroDamageRange, "distance")),
      ...row("chargeUpTime", figure(mode.chargeUpTime, "seconds")),
      ...row("spread", spread(mode.spread)),
      ...row("heatPerShot", figure(mode.heatPerShot)),
      ...row("heatPerSecond", figure(mode.heatPerSecond)),
      ...row("timeToOverheat", figure(mode.timeToOverheat, "seconds")),
      ...row("shotsToOverheat", figure(mode.shotsToOverheat)),
    ],
  });

  const damageDrop = (ammo: EquipmentAmmo) => {
    const drop = ammo.damageDrop;
    const perMeter = damage(drop?.perMeter, precise);
    const minimum = damage(drop?.minDamage);

    if (drop?.minDistance == null || !perMeter) return undefined;

    return t("labels.equipment.gear.damageDropValue", {
      distance: figure(drop.minDistance, "distance"),
      perMeter,
      minimum: minimum || "0",
    });
  };

  const ammo = (key: string, value?: EquipmentAmmo | null) => ({
    key,
    title: t(`labels.equipment.gear.sections.${key}`),
    rows: value
      ? [
          ...row("damage", damage(value.damage)),
          ...row("explosionDamage", damage(value.explosion?.damage)),
          ...row("blastRadius", figure(value.explosion?.maxRadius, "distance")),
          ...row("damageDrop", damageDrop(value), true),
          ...row("speed", figure(value.speed, "speed")),
          ...row("range", figure(value.range, "distance")),
        ]
      : [],
  });

  // The game labels modes for the HUD, and two can share a label -- the
  // Arlington's slug and buckshot are both "Semi", the multi-tool has two
  // "Tractor" actions. Those cards take the mode's own name as well, or a
  // number where that is shared too.
  const distinct = <T extends { name?: string }>(
    entries: T[],
    build: (entry: T, index: number) => GearStatSection,
  ) => {
    const sections = entries.map(build);

    return sections.map((section, index) => {
      const twins = sections.filter((other) => other.title === section.title);
      if (twins.length < 2) return section;

      const name = humanize(entries[index].name);
      const sameName = entries.filter(
        (entry, other) =>
          sections[other].title === section.title &&
          humanize(entry.name) === name,
      );
      const suffix =
        name && sameName.length < 2 ? name : String(twins.indexOf(section) + 1);

      return { ...section, title: `${section.title} · ${suffix}` };
    });
  };

  const toolAction = (action: EquipmentToolAction, index: number) => ({
    key: `tool-action-${index}`,
    title:
      action.label || t(`labels.equipment.gear.toolActions.${action.kind}`),
    rows: [
      ...row(
        "target",
        action.target
          ? t(`labels.equipment.gear.targets.${action.target}`)
          : undefined,
      ),
      ...TOOL_FIELDS.flatMap(({ key, units, scale }) => {
        const value = action[key];
        if (typeof value !== "number") return [];

        return row(key, figure(scale ? value * scale : value, units));
      }),
    ],
  });

  return computed<GearStatSection[]>(() => {
    const value = toValue(stats);
    if (!value) return [];

    const modifier = value.modifier;
    const consumable = value.consumable;
    const buffs = (consumable?.effects || []).filter(
      (effect) => effect.kind === "buff" && effect.buff,
    );

    const sections: GearStatSection[] = [
      ...distinct(value.fireModes || [], fireMode),
      ...distinct(value.toolActions || [], toolAction),
      ammo("ammo", value.ammo),
      ammo("secondaryAmmo", value.secondaryAmmo),
      // A medgun's vial and a multi-tool's battery are containers too, but
      // hold no rounds and are not swapped from a stock of spares.
      {
        key: "magazine",
        title: value.ammo
          ? t("labels.equipment.gear.sections.magazine")
          : label("capacity"),
        rows: [
          ...(value.ammo
            ? [
                ...row("magazineSize", figure(value.magazine?.size)),
                ...row("reserve", figure(value.magazine?.reserve)),
              ]
            : row(
                "capacity",
                figure(value.regen?.capacity ?? value.magazine?.size),
              )),
          ...(value.ammo ? row("capacity", figure(value.regen?.capacity)) : []),
          ...row("regenPerSecond", figure(value.regen?.regenPerSecond)),
          ...row("regenCooldown", figure(value.regen?.cooldown, "seconds")),
        ],
      },
      {
        key: "heat",
        title: t("labels.equipment.gear.sections.heat"),
        rows: [
          ...row("overheatAt", figure(value.heat?.overheatTemperature)),
          ...row("coolingPerSecond", figure(value.heat?.coolingPerSecond)),
          ...row("coolingDelay", figure(value.heat?.coolingDelay, "seconds")),
          ...row(
            "overheatFixTime",
            figure(value.heat?.overheatFixTime, "seconds"),
          ),
        ],
      },
      {
        key: "melee",
        title: t("labels.equipment.gear.sections.melee"),
        rows: (value.melee?.attacks || []).flatMap((attack) => {
          const amount = damage(attack.damage);
          if (!amount || !attack.category) return [];

          return [
            {
              label: t(`labels.equipment.gear.meleeAttacks.${attack.category}`),
              value: amount,
            },
          ];
        }),
      },
      {
        key: "explosion",
        title: t("labels.equipment.gear.sections.explosion"),
        rows: [
          ...row("damage", damage(value.explosion?.damage)),
          ...row("blastRadius", figure(value.explosion?.maxRadius, "distance")),
          ...row("fuse", figure(value.explosion?.fuse, "seconds")),
          ...row(
            "trigger",
            value.mine?.trigger
              ? t(`labels.equipment.gear.triggers.${value.mine.trigger}`)
              : undefined,
          ),
          ...row("triggerRadius", figure(value.mine?.radius, "distance")),
          ...row(
            "warningRadius",
            figure(value.mine?.warningRadius, "distance"),
          ),
          ...row("laserLength", figure(value.mine?.length, "distance")),
        ],
      },
      {
        key: "modifier",
        title: t("labels.equipment.gear.sections.modifier"),
        rows: [
          ...row("damage", change(modifier?.damage)),
          ...row("fireRate", change(modifier?.fireRate)),
          ...row("projectileSpeed", change(modifier?.projectileSpeed)),
          ...row("heat", change(modifier?.heat)),
          ...row("spreadMin", change(modifier?.spread?.min)),
          ...row("spreadMax", change(modifier?.spread?.max)),
          ...row("spreadFirstAttack", change(modifier?.spread?.firstAttack)),
          ...row("spreadGrowth", change(modifier?.spread?.attack)),
          ...row("spreadRecovery", change(modifier?.spread?.decay)),
          ...row("recoilYaw", change(modifier?.recoil?.yaw)),
          ...row("recoilPitch", change(modifier?.recoil?.pitch)),
          ...row("soundRadius", change(modifier?.soundRadius)),
          ...row(
            "zoom",
            modifier?.zoom != null ? `${figure(modifier.zoom)}×` : undefined,
          ),
          ...row(
            "secondZoom",
            modifier?.secondZoom != null
              ? `${figure(modifier.secondZoom)}×`
              : undefined,
          ),
          ...row("zoomTime", change(modifier?.zoomTime)),
        ],
      },
      {
        key: "mining",
        title: t("labels.equipment.gear.sections.mining"),
        rows: [
          ...Object.entries(value.mining?.modifiers || {}).flatMap(
            ([key, amount]) =>
              amount == null
                ? []
                : [
                    {
                      label: t(`labels.hardpoint.mining.modifiers.${key}`),
                      value: percentChange(amount) as string,
                    },
                  ],
          ),
          ...row("charges", figure(value.mining?.charges)),
        ],
      },
      {
        key: "consumable",
        title: t("labels.equipment.gear.sections.consumable"),
        rows: [
          ...(consumable?.effects || []).flatMap((effect) => {
            if (effect.kind === "health") {
              return row("health", figure(effect.amount));
            }
            if (effect.kind === "status" && effect.stat) {
              return [
                {
                  label: t(`labels.equipment.gear.bodyStats.${effect.stat}`),
                  value: figure(effect.amount) as string,
                },
              ];
            }

            return [];
          }),
          ...row(
            "effects",
            buffs.length
              ? buffs
                  .map((effect) => {
                    const name = t(
                      `labels.equipment.gear.buffs.${effect.buff}`,
                    );

                    return effect.duration
                      ? `${name} (${figure(effect.duration, "seconds")})`
                      : name;
                  })
                  .join(", ")
              : undefined,
            true,
          ),
        ],
      },
    ];

    return sections.filter((section) => section.rows.length);
  });
};
