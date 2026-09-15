import { describe, expect, it } from "vitest";
import { presetCatalogue, presetImageUrl } from "./usePresetImages";

describe("usePresetImages", () => {
  // Dropping art into the folder is meant to be the whole change.
  it("takes a catalogue from its folder rather than a list", () => {
    const { presets } = presetCatalogue("missions");

    expect(presets.length).toBeGreaterThan(0);
    expect(presets.every((preset) => !!preset.url)).toBe(true);
  });

  it("files an alternate under the category it is an alternate of", () => {
    const { presets } = presetCatalogue("missions");

    const alternate = presets.find((preset) => preset.key === "mining_alt1");

    expect(alternate?.group).toBe("mining");
  });

  // `ship_combat_alt1` split on the first underscore would land under "ship",
  // which is not a category and would put it on a chip of its own.
  it("does not split a two-word category in half", () => {
    const { presets, groups } = presetCatalogue("missions");

    expect(
      presets.find((preset) => preset.key === "ship_combat_alt1")?.group,
    ).toBe("ship_combat");
    expect(groups).not.toContain("ship");
  });

  it("leads each group with the plain cover, then its alternates", () => {
    const mining = presetCatalogue("missions")
      .presets.filter((preset) => preset.group === "mining")
      .map((preset) => preset.key);

    expect(mining[0]).toBe("mining");
    expect(mining.slice(1)).toEqual([...mining.slice(1)].sort());
  });

  // No enum to keep in step: an inventory is not a kind of thing, so the
  // picker shows every picture at once and renders no chips at all.
  it("leaves an inventory picture ungrouped", () => {
    const { presets, groups } = presetCatalogue("inventories");

    expect(groups).toEqual([]);
    expect(presets.every((preset) => preset.group === undefined)).toBe(true);
  });

  // Only what was put there for this. The picker briefly borrowed a handful of
  // page backdrops to pad the list out; they are backdrops, and they read as
  // backdrops behind a panel this size.
  it("takes inventory art from its own folder and nowhere else", () => {
    const keys = presetCatalogue("inventories").presets.map((p) => p.key);

    expect(keys).toEqual(["placeholder-1", "placeholder-2", "placeholder-3"]);
  });

  it("resolves a key to a URL, and an unknown one to nothing", () => {
    expect(presetImageUrl("missions", "mining")).toBeTruthy();
    expect(presetImageUrl("missions", "no_such_preset")).toBeUndefined();
    expect(presetImageUrl("missions", null)).toBeUndefined();
  });

  // Two formats of one picture are one entry: the folder ships webp plus a
  // fallback for nearly every cover.
  it("holds one picture per name", () => {
    const keys = presetCatalogue("missions").presets.map((p) => p.key);

    expect(new Set(keys).size).toBe(keys.length);
  });
});
