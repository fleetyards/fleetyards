import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Entry from "@/frontend/components/Compare/Builds/Entry/index.vue";
import type { ScDataDiffEntry } from "@/services/fyApi";

const entry = (fields: ScDataDiffEntry["fields"]): ScDataDiffEntry => ({
  id: "11111111-1111-4111-8111-111111111111",
  kind: "changed",
  name: "Cerrado Boots",
  fields,
});

const render = (item: ScDataDiffEntry, field?: string) =>
  mountWithDefaults(Entry, {
    props: { entry: item, catalogue: "equipment", field },
  });

describe("CompareBuildsEntry", () => {
  it("names the record and both values, never its id", async () => {
    const wrapper = await render(
      entry([{ field: "hull_health", from: 37800, to: 33600 }]),
    );

    expect(wrapper.text()).toContain("Cerrado Boots");
    expect(wrapper.text()).toContain("Hull health");
    expect(wrapper.text()).toContain("−11%");
    expect(wrapper.text()).not.toContain("11111111-");
  });

  it("keeps small values apart and states zero and absence", async () => {
    const wrapper = await render(
      entry([
        { field: "volume", from: 0.0144, to: 0.003 },
        { field: "mass", from: 125, to: 0 },
        { field: "sub_type", from: null, to: "Heavy" },
      ]),
    );
    const facts = wrapper.findAll('[data-test="build-diff-fact"]');

    expect(facts[0]?.text()).toContain("0.0144");
    expect(facts[0]?.text()).toContain("0.003");
    expect(facts[1]?.text()).toContain("−100%");
    expect(facts[2]?.text()).toContain("None");
  });

  it("never shows a change as two equal values", async () => {
    const wrapper = await render(
      entry([
        { field: "range", from: 10.21, to: 10.24 },
        { field: "durability.resistances.energy", from: 0.841, to: 0.844 },
        { field: "durability.mass", from: 10, to: 20 },
      ]),
    );
    const facts = wrapper.findAll('[data-test="build-diff-fact"]');

    facts.forEach((fact) => {
      const [before, after] = ["old", "new"].map((side) =>
        fact.find(`.build-diff-entry__${side}`).text(),
      );
      expect(before).not.toBe(after);
    });
  });

  it("shows one fact where the list is about it", async () => {
    const wrapper = await render(
      entry([
        { field: "volume", from: 1, to: 2 },
        { field: "size", from: "1", to: "2" },
      ]),
      "size",
    );

    expect(wrapper.findAll('[data-test="build-diff-fact"]')).toHaveLength(1);
  });
});
