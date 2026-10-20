import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  type GameMission,
  type GameMissionPrerequisite,
  GameMissionPrerequisiteKindEnum,
} from "@/services/fyApi";
import Component from "./index.vue";

// A linked mission resolves its target by route name, which the default
// single-route test router cannot.
const missionRouter = () =>
  createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      {
        path: "/missions/:slug",
        name: "mission",
        component: { template: "<div />" },
      },
    ],
  });

const prerequisite = (
  attrs: Partial<GameMissionPrerequisite>,
): GameMissionPrerequisite => ({
  kind: GameMissionPrerequisiteKindEnum.CRIME_STAT,
  excluded: false,
  includesSelf: false,
  missions: [],
  ...attrs,
});

const intro = {
  id: "0f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c",
  name: "Wikelo Arrive to System",
  slug: "thecollector-thecollector-intro",
};

const mount = (attrs: Partial<GameMission>) =>
  mountWithDefaults(Component, {
    props: {
      mission: {
        id: "1f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c",
        slug: "test-armor",
        scKey: "thecollector_thecollector_battle",
        scRef: "318bc17e-1b97-4ba5-a527-0c81076ef811",
        retired: false,
        released: true,
        needsLanding: false,
        rewardKinds: [],
        createdAt: "",
        updatedAt: "",
        ...attrs,
      } as GameMission,
    },
    plugins: [missionRouter()],
  });

describe("MissionAvailability", () => {
  it("states the per-player limit and when it is offered again", async () => {
    const wrapper = await mount({
      maxInstancesPerPlayer: 1,
      respawnTime: 5,
      respawnVariation: 2,
    });

    expect(wrapper.text()).toContain("One at a time per player");
    expect(wrapper.text()).toContain("Offered again after 5 ± 2 min");
  });

  it("states a crime stat band and a reputation band to stay outside of", async () => {
    const wrapper = await mount({
      prerequisites: [
        prerequisite({ min: 0, max: 2 }),
        prerequisite({
          kind: GameMissionPrerequisiteKindEnum.REPUTATION,
          orgName: "Foxwell Enforcement",
          minStanding: "Elite Contractor",
          maxStanding: "Elite Contractor",
          excluded: true,
        }),
      ],
    });

    expect(wrapper.text()).toContain("CrimeStat 0 – 2");
    expect(wrapper.text()).toContain(
      "Not Elite Contractor with Foxwell Enforcement",
    );
  });

  it("links the mission to complete first", async () => {
    const wrapper = await mount({
      prerequisites: [
        prerequisite({
          kind: GameMissionPrerequisiteKindEnum.COMPLETED_MISSIONS,
          count: 1,
          missions: [intro],
        }),
      ],
    });

    const popover = wrapper.findComponent({ name: "CatalogueItemPopover" });

    expect(wrapper.text()).toContain("Complete first");
    expect(popover.props("item")).toMatchObject({
      type: "GameMission",
      slug: intro.slug,
    });
  });

  it("counts towards several missions, or ones the catalogue does not list", async () => {
    const wrapper = await mount({
      prerequisites: [
        prerequisite({
          kind: GameMissionPrerequisiteKindEnum.COMPLETED_MISSIONS,
          count: 5,
          missions: [intro],
        }),
        prerequisite({
          kind: GameMissionPrerequisiteKindEnum.COMPLETED_MISSIONS,
          count: 500,
        }),
      ],
    });

    expect(wrapper.text()).toContain("Complete 5 of");
    expect(wrapper.text()).toContain(
      "Complete 500 missions not in the catalogue",
    );
  });

  it("says once only where the mission rules itself out", async () => {
    const wrapper = await mount({
      prerequisites: [
        prerequisite({
          kind: GameMissionPrerequisiteKindEnum.EXCLUDED_MISSIONS,
          includesSelf: true,
        }),
      ],
    });

    expect(wrapper.text()).toContain("Once only");
  });

  it("reads a band open at the top as a minimum", async () => {
    const wrapper = await mount({
      prerequisites: [
        prerequisite({
          kind: GameMissionPrerequisiteKindEnum.REPUTATION,
          orgName: "Shubin Interstellar",
          minStanding: "Neutral",
        }),
      ],
    });

    expect(wrapper.text()).toContain(
      "Neutral or higher with Shubin Interstellar",
    );
  });

  it("renders nothing for a mission that states none of it", async () => {
    const wrapper = await mount({});

    expect(wrapper.find(".mission-availability").exists()).toBe(false);
  });
});
