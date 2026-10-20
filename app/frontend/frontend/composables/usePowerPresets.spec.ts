import { describe, expect, it } from "vitest";
import { presetFrom, presetMatches, presetOverrides } from "./usePowerPresets";

describe("power presets", () => {
  it("stores overrides as a list in port order and reads them back", () => {
    const preset = presetFrom("Dogfight", "SCM", { shield: 2, radar: 0 });

    expect(preset.overrides).toEqual([
      { portPath: "radar", pips: 0 },
      { portPath: "shield", pips: 2 },
    ]);
    expect(presetOverrides(preset)).toEqual({ shield: 2, radar: 0 });
  });

  it("matches only the same mode and the same pips", () => {
    const preset = presetFrom("Dogfight", "SCM", { shield: 2 });

    expect(presetMatches(preset, "SCM", { shield: 2 })).toBe(true);
    expect(presetMatches(preset, "NAV", { shield: 2 })).toBe(false);
    expect(presetMatches(preset, "SCM", { shield: 3 })).toBe(false);
    expect(presetMatches(preset, "SCM", { shield: 2, radar: 1 })).toBe(false);
  });
});
