import { describe, expect, it } from "vitest";
import { presetFrom, presetMatches, presetSplits } from "./usePowerPresets";

describe("power presets", () => {
  it("keeps both modes' splits as lists in port order and reads them back", () => {
    const preset = presetFrom("Dogfight", {
      SCM: { shield: 2, radar: 0 },
      NAV: { qdrive: 3 },
    });

    expect(preset.scm).toEqual([
      { portPath: "radar", pips: 0 },
      { portPath: "shield", pips: 2 },
    ]);
    expect(preset.nav).toEqual([{ portPath: "qdrive", pips: 3 }]);
    expect(presetSplits(preset)).toEqual({
      SCM: { shield: 2, radar: 0 },
      NAV: { qdrive: 3 },
    });
  });

  it("matches only when both modes carry the same pips", () => {
    const preset = presetFrom("Dogfight", { SCM: { shield: 2 }, NAV: {} });

    expect(presetMatches(preset, { SCM: { shield: 2 }, NAV: {} })).toBe(true);
    expect(presetMatches(preset, { SCM: { shield: 3 }, NAV: {} })).toBe(false);
    expect(
      presetMatches(preset, { SCM: { shield: 2 }, NAV: { radar: 1 } }),
    ).toBe(false);
  });
});
