import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { missionTextPlain } from "@/frontend/components/MissionText/index";
import type { GameMission } from "@/services/fyApi";
import MissionStatsCard from "./index.vue";

const router = () =>
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

const NAME = "Bounty: <EM4>~mission(TargetName)</EM4> wanted";

const mission = (overrides: Partial<GameMission> = {}) =>
  ({
    id: "1",
    name: NAME,
    slug: "bounty",
    kind: "career",
    org: { name: "Vaughn" },
    retired: false,
    released: true,
    ...overrides,
  }) as unknown as GameMission;

const mount = (record: GameMission) =>
  mountWithDefaults(MissionStatsCard, {
    props: { mission: record },
    plugins: [router()],
  });

describe("MissionStatsCard", () => {
  it("titles itself with the game's markup taken out", async () => {
    const wrapper = await mount(mission());

    const title = wrapper.find(".stats-card__title").text();
    expect(title).toBe(missionTextPlain(NAME));
    expect(title).not.toContain("<EM4>");
  });

  it("marks an unreleased mission", async () => {
    const wrapper = await mount(mission({ released: false }));

    const status = wrapper.find("[data-test='stats-card-status']");
    expect(status.classes()).toContain("stats-card__status--warning");
  });

  it("marks a retired one as retired even if it never released", async () => {
    const wrapper = await mount(mission({ retired: true, released: false }));

    const status = wrapper.find("[data-test='stats-card-status']");
    expect(status.classes()).toContain("stats-card__status--neutral");
  });
});
