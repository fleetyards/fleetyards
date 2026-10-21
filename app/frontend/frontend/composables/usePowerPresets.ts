import type { ComputedRef, InjectionKey, MaybeRefOrGetter } from "vue";
import type { PowerPreset, PowerPresetOverride } from "@/services/fyApi";
import type {
  PortOverrides,
  PowerSplits,
} from "@/frontend/composables/powerSim";

export interface PowerPresets {
  presets: ComputedRef<PowerPreset[]>;
  // Only the loadout's owner keeps presets; a visitor of a shared loadout
  // applies them.
  editable: ComputedRef<boolean>;
  saving: ComputedRef<boolean>;
  save: (presets: PowerPreset[]) => Promise<boolean>;
}

const POWER_PRESETS: InjectionKey<PowerPresets> = Symbol("powerPresets");

export const providePowerPresets = (options: {
  presets: MaybeRefOrGetter<PowerPreset[] | undefined>;
  editable: MaybeRefOrGetter<boolean>;
  saving: MaybeRefOrGetter<boolean>;
  save: (presets: PowerPreset[]) => Promise<boolean>;
}) => {
  provide(POWER_PRESETS, {
    presets: computed(() => toValue(options.presets) ?? []),
    editable: computed(() => toValue(options.editable)),
    saving: computed(() => toValue(options.saving)),
    save: options.save,
  });
};

// Only a saved loadout has presets; on a ship's own page there are none.
export const injectPowerPresets = () => inject(POWER_PRESETS, undefined);

const toOverrides = (list: PowerPresetOverride[]): PortOverrides =>
  Object.fromEntries(
    list.map((override) => [override.portPath, override.pips]),
  );

const toList = (overrides: PortOverrides): PowerPresetOverride[] =>
  Object.entries(overrides)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([portPath, pips]) => ({ portPath, pips }));

export const presetSplits = (preset: PowerPreset): PowerSplits => ({
  SCM: toOverrides(preset.scm),
  NAV: toOverrides(preset.nav),
});

export const presetFrom = (name: string, splits: PowerSplits): PowerPreset => ({
  name,
  scm: toList(splits.SCM),
  nav: toList(splits.NAV),
});

const sameOverrides = (a: PortOverrides, b: PortOverrides) => {
  const keys = new Set([...Object.keys(a), ...Object.keys(b)]);
  return [...keys].every((key) => a[key] === b[key]);
};

export const presetMatches = (preset: PowerPreset, splits: PowerSplits) => {
  const own = presetSplits(preset);
  return (
    sameOverrides(own.SCM, splits.SCM) && sameOverrides(own.NAV, splits.NAV)
  );
};

// As many as the API keeps, and as long a name.
export const MAX_POWER_PRESETS = 5;
export const MAX_POWER_PRESET_NAME = 40;
