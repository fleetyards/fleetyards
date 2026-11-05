import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  type GameMissionReward,
  GameMissionRewardKindEnum,
  NullableGameMissionRewardOutcomeEnum,
} from "@/services/fyApi";
import Component from "./index.vue";

const routerWithFaction = () =>
  createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      {
        path: "/catalogue/factions/:slug",
        name: "faction",
        component: { template: "<div />" },
      },
    ],
  });

const reputation = (attrs: Partial<GameMissionReward> = {}) => ({
  kind: GameMissionRewardKindEnum.REPUTATION,
  amount: 250,
  orgName: "Red Wind Linehaul",
  orgSlug: "redwindlinehaul",
  ladderName: "Hauling",
  outcome: NullableGameMissionRewardOutcomeEnum.COMPLETED,
  ...attrs,
});

const mountRewards = (rewards: GameMissionReward[]) =>
  mountWithDefaults(Component, {
    props: { rewards },
    plugins: [routerWithFaction()],
  });

describe("Missions/Rewards", () => {
  it("states the ladder a reputation amount feeds and links its faction", async () => {
    const wrapper = await mountRewards([reputation()]);

    expect(wrapper.text()).toContain("+250");
    expect(wrapper.text()).toContain("Hauling");
    expect(wrapper.find("a").attributes("href")).toContain(
      "/catalogue/factions/redwindlinehaul",
    );
  });

  it("tells a loss on not completing from a gain on completing", async () => {
    const wrapper = await mountRewards([
      reputation(),
      reputation({
        amount: -1000,
        outcome: NullableGameMissionRewardOutcomeEnum.NOT_COMPLETED,
      }),
    ]);

    const [gain, loss] = wrapper
      .findAll("[data-test='reward-outcome']")
      .map((outcome) => outcome.text());

    expect(gain).toBeTruthy();
    expect(loss).toBeTruthy();
    expect(gain).not.toEqual(loss);
  });

  it("shows an org with no faction page as plain text, and no outcome it does not know", async () => {
    const wrapper = await mountRewards([
      reputation({ orgSlug: null, outcome: null }),
    ]);

    expect(wrapper.find("a").exists()).toBe(false);
    expect(wrapper.text()).toContain("Red Wind Linehaul");
    expect(wrapper.find("[data-test='reward-outcome']").exists()).toBe(false);
  });
});
