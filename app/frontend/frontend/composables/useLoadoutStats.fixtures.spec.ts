import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { describe, expect, it } from "vitest";
import type { Hardpoint } from "@/services/fyApi";
import type { WeaponRegenModifier } from "./powerSim";
import { computeFirepower, type Firepower } from "./useLoadoutStats";

// Real ships' hardpoint trees, as the hardpoints endpoint renders them, with
// the firepower they come to. `test/models/loadout_firepower_test.rb` reads the
// same files, so the server's figures and these cannot drift apart unnoticed.
// After a change to the arithmetic made on purpose, on both sides,
// `UPDATE_LOADOUT_STATS_FIXTURES=1` writes the new figures in.
const directory = resolve(__dirname, "../../../../test/fixtures/loadout_stats");

type Fixture = {
  ship: string;
  weaponPoolSize?: number;
  regenModifier?: WeaponRegenModifier;
  hardpoints: Hardpoint[];
  expected?: Firepower;
};

const files = readdirSync(directory).filter((file) => file.endsWith(".json"));

describe("computeFirepower against the shared fixtures", () => {
  it("has fixtures to check", () => {
    expect(files.length).toBeGreaterThan(0);
  });

  it.each(files)("%s", (file) => {
    const path = join(directory, file);
    const fixture = JSON.parse(readFileSync(path, "utf8")) as Fixture;
    const firepower = computeFirepower(
      fixture.hardpoints,
      fixture.weaponPoolSize,
      fixture.regenModifier,
    );

    if (process.env.UPDATE_LOADOUT_STATS_FIXTURES) {
      writeFileSync(
        path,
        `${JSON.stringify({ ...fixture, expected: firepower }, null, 2)}\n`,
      );
      return;
    }

    expect(fixture.expected).toBeDefined();
    for (const [key, value] of Object.entries(fixture.expected!)) {
      expect(firepower[key as keyof Firepower]).toBeCloseTo(value, 6);
    }
  });
});
