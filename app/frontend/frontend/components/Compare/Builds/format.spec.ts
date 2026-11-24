import { describe, expect, it } from "vitest";
import {
  buildLabel,
  defaultPair,
  entryRoute,
  fieldKey,
  movement,
  slotPosition,
} from "@/frontend/components/Compare/Builds/format";

const build = (environment: string, version: string) => ({
  environment,
  version,
});

const ptu = build("ptu", "5.0.0-ptu.40");
const live = build("live", "4.10.3-live.30");
const hotfixed = build("live", "4.10.3-live.29");
const previous = build("live", "4.10.2-live.20");

describe("defaultPair", () => {
  it("opens on live against a preview that is offered", () => {
    expect(defaultPair([ptu, live, previous], [live, ptu])).toEqual({
      from: live.version,
      to: ptu.version,
    });
  });

  it("opens on the last two live patches without one, past a hotfix", () => {
    expect(defaultPair([ptu, live, hotfixed, previous], [live])).toEqual({
      from: previous.version,
      to: live.version,
    });
  });

  it("has nothing to open on with a single build", () => {
    expect(defaultPair([live], [live])).toBeUndefined();
  });
});

describe("defaultPair while a build loads", () => {
  it("stays on the build being served", () => {
    const loading = build("live", "4.10.4-live.50");

    expect(defaultPair([loading, live, previous], [live])).toEqual({
      from: previous.version,
      to: live.version,
    });
  });
});

describe("build diff formatting", () => {
  it("labels a build by channel, release and id", () => {
    expect(buildLabel(live)).toBe("LIVE 4.10.3 (30)");
  });

  it("reads the last part of a nested field", () => {
    expect(fieldKey("durability.resistances.energy")).toBe("energy");
    expect(fieldKey("type_data.max_health")).toBe("maxHealth");
  });

  it("states how far a number moved, and nothing for text", () => {
    expect(movement({ field: "a", from: 100, to: 62 })).toBe("−38%");
    expect(movement({ field: "a", from: 0, to: 5 })).toBeUndefined();
    expect(movement({ field: "a", from: "x", to: "y" })).toBeUndefined();
  });

  it("names where a slot is, in translated words", () => {
    const upper = (word: string) => word.toUpperCase();

    expect(slotPosition("hardpoint_turret_rear_left_02", upper)).toBe(
      "REAR LEFT 2",
    );
    expect(slotPosition("hardpoint_radar", upper)).toBe("");
  });

  it("links a record only with a slug and a page", () => {
    expect(entryRoute("models", "javelin")).toEqual({
      name: "ship",
      params: { slug: "javelin" },
    });
    expect(entryRoute("models")).toBeUndefined();
    expect(entryRoute("modules", "cargo")).toBeUndefined();
  });
});
