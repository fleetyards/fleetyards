import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type GameMission } from "@/services/fyApi";
import Component from "./index.vue";

// The row links to the mission and back into the list it is being read from,
// and `filterLink` builds its target off the current route's name -- so the
// default single-route test router cannot resolve either.
const routerOnList = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/catalogue/missions",
        name: "missions",
        component: { template: "<div />" },
      },
      {
        path: "/catalogue/missions/:slug",
        name: "mission",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({ name: "missions" });
  await router.isReady();

  return router;
};

const mission = (attrs: Partial<GameMission> = {}) =>
  ({
    id: "0f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c",
    name: "Yellow Level Contract: Ambush An Amateur",
    slug: "foxwellenforcement-ambush-veryeasy",
    scKey: "foxwellenforcement_ambush_veryeasy",
    scRef: "3f2a4d41-0000-4000-8000-000000000001",
    retired: false,
    released: true,
    rewardKinds: ["reputation"],
    ...attrs,
  }) as GameMission;

const mount = async (attrs: Partial<GameMission> = {}) =>
  mountWithDefaults(Component, {
    props: { mission: mission(attrs) },
    plugins: [await routerOnList()],
  });

describe("MissionRow", () => {
  it("renders the title with its substitutions named", async () => {
    const wrapper = await mount({ name: "Wanted: ~mission(TargetName)" });

    expect(wrapper.text()).toContain("Wanted:");
    expect(wrapper.text()).toContain("TargetName");
    expect(wrapper.text()).not.toContain("~mission(");
  });

  // Both ends are set on 2,155 of the 2,536 and are frequently the same rank,
  // which reads as "Neutral" rather than "Neutral – Neutral".
  it("collapses a band whose ends are the same rank", async () => {
    const wrapper = await mount({
      minStanding: "Neutral",
      maxStanding: "Neutral",
    });

    expect(wrapper.text()).toContain("Neutral");
    expect(wrapper.text()).not.toContain("Neutral – Neutral");
  });

  it("names both ends of a band that spans two ranks", async () => {
    const wrapper = await mount({
      minStanding: "Neutral",
      maxStanding: "Elite Contractor",
    });

    expect(wrapper.text()).toContain("Neutral – Elite Contractor");
  });

  // A plain mean of the four axes, not the game's per-profile weighting: the
  // weights are a record the export states separately, and applying one here
  // would be publishing a number the game does not.
  it("shows the four difficulty axes as one figure", async () => {
    const wrapper = await mount({
      difficulty: {
        profile: "general",
        mechanicalSkill: 5,
        mentalLoad: 3,
        riskOfLoss: 3,
        gameKnowledge: 1,
      },
    });

    expect(wrapper.text()).toContain("3/7");
  });

  it("says nothing about difficulty where the export states none", async () => {
    const wrapper = await mount();

    expect(wrapper.text()).not.toContain("/7");
  });

  // Said on the row, because a reader hunting the mission in game needs to
  // know before they click that it is not in front of anybody.
  it("marks a mission the build is not offering", async () => {
    const wrapper = await mount({ released: false });

    expect(wrapper.find(".row-list-item__badge--quiet").exists()).toBe(true);
  });

  it("leaves the mark off one the build is offering", async () => {
    const wrapper = await mount();

    expect(wrapper.find(".row-list-item__badge--quiet").exists()).toBe(false);
  });

  it("links the org back into the list it narrows", async () => {
    const wrapper = await mount({
      org: { name: "Headhunters", key: "headhunters", alignment: "outlaw" },
    });

    const link = wrapper.find(".row-list-item__sub a");

    expect(link.attributes("href")).toContain("orgNameIn");
    expect(link.text()).toBe("Headhunters");
  });
});
