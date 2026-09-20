import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type BlueprintSource } from "@/services/fyApi";
import Component from "./index.vue";

const ALIGNMENT = ".blueprint-sources__alignment";
const GROUP_HEAD = ".blueprint-sources__group-head";

const source = (attrs: Partial<BlueprintSource> = {}) =>
  ({
    kind: "contract",
    orgName: "Foxwell Enforcement",
    alignment: "lawful",
    missionName: "Yellow Level Contract: Ambush An Amateur",
    minStanding: "Neutral",
    ...attrs,
  }) as BlueprintSource;

const mount = (sources: BlueprintSource[]) =>
  mountWithDefaults(Component, { props: { sources } });

describe("Blueprints/Sources", () => {
  it("badges a group with the alignment of the org that hands it out", async () => {
    const wrapper = await mount([source()]);

    const badge = wrapper.find(ALIGNMENT);

    expect(badge.exists()).toBe(true);
    expect(badge.text()).toBe("Lawful");
    expect(badge.classes()).toContain("blueprint-sources__alignment--lawful");
  });

  // Colour is what separates the three, so the modifier has to follow the
  // value rather than only being present.
  it("carries the alignment into the modifier class", async () => {
    const wrapper = await mount([
      source({ orgName: "Headhunters", alignment: "outlaw" }),
      source({ orgName: "Wikelo Emporium", alignment: "neutral" }),
    ]);

    expect(wrapper.findAll(ALIGNMENT).map((badge) => badge.classes())).toEqual([
      expect.arrayContaining(["blueprint-sources__alignment--outlaw"]),
      expect.arrayContaining(["blueprint-sources__alignment--neutral"]),
    ]);
  });

  // Nine source entries sit in a generator naming more than one faction. A
  // badge there would be a guess, and the group already says "Unattributed".
  it("badges nothing where the source has no org", async () => {
    const wrapper = await mount([
      source({ orgName: undefined, alignment: undefined }),
    ]);

    expect(wrapper.find(GROUP_HEAD).exists()).toBe(true);
    expect(wrapper.find(ALIGNMENT).exists()).toBe(false);
  });

  // One org, one answer -- but a group is built from many entries, and taking
  // the badge off the wrong one would be invisible until an org disagreed with
  // itself.
  it("badges each org group once", async () => {
    const wrapper = await mount([
      source({ orgName: "Headhunters", alignment: "outlaw" }),
      source({ orgName: "Headhunters", alignment: "outlaw" }),
      source({ orgName: "Foxwell Enforcement", alignment: "lawful" }),
    ]);

    expect(wrapper.findAll(GROUP_HEAD)).toHaveLength(2);
    expect(wrapper.findAll(ALIGNMENT).map((badge) => badge.text())).toEqual([
      "Outlaw",
      "Lawful",
    ]);
  });
});
