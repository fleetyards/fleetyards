import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type GameMission } from "@/services/fyApi";
import Component from "./index.vue";

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/missions",
        name: "missions",
        component: { template: "<div />" },
      },
      {
        path: "/missions/:slug",
        name: "mission",
        component: { template: "<div />" },
      },
    ],
  });

  await instance.push({ name: "missions" });
  await instance.isReady();

  return instance;
};

const mission = (id: string, name: string, org?: string) =>
  ({
    id,
    name,
    slug: id,
    scKey: id,
    scRef: id,
    retired: false,
    released: true,
    needsLanding: false,
    rewardKinds: [],
    org: org
      ? { name: org, key: org, alignment: "lawful", lawful: true }
      : null,
    minStanding: "Neutral",
    createdAt: "2026-10-01T00:00:00Z",
    updatedAt: "2026-10-01T00:00:00Z",
  }) as unknown as GameMission;

describe("LocationMissions", () => {
  it("groups the missions by who offers them, the largest group open", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        missions: [
          mission("a", "Blackbox Retrieval", "Recco Battaglia"),
          mission("b", "Med. Distance Covalex Delivery Nyx", "Covalex"),
          mission("c", "Long Distance Covalex Delivery Nyx", "Covalex"),
        ],
        total: 126,
        locationId: "levski",
      },
      plugins: [await router()],
    });

    const orgs = wrapper
      .findAll(".location-missions__org")
      .map((org) => org.text());

    expect(orgs).toEqual(["Covalex", "Recco Battaglia"]);
    expect(wrapper.findAll(".location-missions__mission")).toHaveLength(2);
    expect(wrapper.text()).toContain("126");
    expect(wrapper.find(".location-missions__all").exists()).toBe(true);
  });

  it("marks a mission players cannot get yet, and says the counts are a sample", async () => {
    const unreleased = {
      ...mission("d", "Hauling Test", "Covalex"),
      released: false,
    } as GameMission;

    const wrapper = await mountWithDefaults(Component, {
      props: { missions: [unreleased], total: 126, locationId: "levski" },
      plugins: [await router()],
    });

    expect(
      wrapper.find('[data-test="location-mission-unreleased"]').exists(),
    ).toBe(true);
    expect(wrapper.get(".location-missions__sample").text()).toBe(
      "Counts cover the first 1 of 126.",
    );
  });
});
