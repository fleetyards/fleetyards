import type { ComputedRef, InjectionKey, MaybeRefOrGetter } from "vue";
import type { PowerPreset } from "@/services/fyApi";
import type {
  FlightMode,
  PortOverrides,
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

export const presetOverrides = (preset: PowerPreset): PortOverrides =>
  Object.fromEntries(
    preset.overrides.map((override) => [override.portPath, override.pips]),
  );

export const presetFrom = (
  name: string,
  mode: FlightMode,
  overrides: PortOverrides,
): PowerPreset => ({
  name,
  mode,
  overrides: Object.entries(overrides)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([portPath, pips]) => ({ portPath, pips })),
});

export const presetMatches = (
  preset: PowerPreset,
  mode: FlightMode,
  overrides: PortOverrides,
) => {
  if (preset.mode !== mode) return false;

  const own = presetOverrides(preset);
  const keys = new Set([...Object.keys(own), ...Object.keys(overrides)]);

  return [...keys].every((key) => own[key] === overrides[key]);
};

// As many as the API keeps.
export const MAX_POWER_PRESETS = 20;
