import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  type GameMissionHandIn,
  GameMissionCatalogueItemTypeEnum,
  GameMissionHandInKindEnum,
} from "@/services/fyApi";
import Component from "./index.vue";

const handIn = (attrs: Partial<GameMissionHandIn> = {}): GameMissionHandIn => ({
  kind: GameMissionHandInKindEnum.ITEM,
  ref: "124da32f-de8f-45f6-a2f1-81fd47752b2d",
  name: "Yormandi Eye",
  amount: 14,
  ...attrs,
});

// A catalogue link resolves its target by route name, which the default
// single-route test router cannot.
const catalogueRouter = () =>
  createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      {
        path: "/commodities/:slug",
        name: "commodity",
        component: { template: "<div />" },
      },
    ],
  });

const mount = (handIns: GameMissionHandIn[]) =>
  mountWithDefaults(Component, {
    props: { handIns },
    plugins: [catalogueRouter()],
  });

describe("MissionHandIns", () => {
  it("lists an item by count and a resource in SCU", async () => {
    const wrapper = await mount([
      handIn(),
      handIn({
        kind: GameMissionHandInKindEnum.RESOURCE,
        ref: "a0e6c4cf-face-4f52-a020-dfa869607901",
        name: "Recycled Material Composite",
        amount: 5,
      }),
    ]);

    expect(wrapper.text()).toContain("14× Yormandi Eye");
    expect(wrapper.text()).toContain("5 SCU Recycled Material Composite");
  });

  it("states a range where the contract gives one", async () => {
    const wrapper = await mount([
      handIn({ name: "SRT Canister", amount: 1, max: 4 }),
    ]);

    expect(wrapper.text()).toContain("1 – 4× SRT Canister");
  });

  it("groups a choice under its own label", async () => {
    const wrapper = await mount([
      handIn({ name: "Aphorite", amount: 15, option: 0 }),
      handIn({ name: "Hadanite", amount: 5, option: 1 }),
    ]);

    const items = wrapper.findAll(".mission-rewards__item");

    expect(wrapper.text()).toContain("One of these");
    expect(items).toHaveLength(2);
    expect(items[0].text()).toContain("15× Aphorite");
    expect(items[1].text()).toContain("5× Hadanite");
  });

  it("joins the entries of one option", async () => {
    const wrapper = await mount([
      handIn({ name: "Aphorite", amount: 15, option: 0 }),
      handIn({ name: "Hadanite", amount: 5, option: 0 }),
    ]);

    const items = wrapper.findAll(".mission-rewards__item");

    expect(items).toHaveLength(1);
    expect(items[0].text()).toMatch(/15× Aphorite\s*\+\s*5× Hadanite/);
  });

  it("opens the catalogue card for a hand-in the catalogue carries", async () => {
    const wrapper = await mount([
      handIn({
        kind: GameMissionHandInKindEnum.RESOURCE,
        name: "Quartz",
        amount: 2,
        catalogueItem: {
          type: GameMissionCatalogueItemTypeEnum.COMMODITY,
          id: "5d1e0c3a-0000-4000-8000-0000000000c2",
          name: "Quartz",
          slug: "quartz",
          listed: true,
        },
      }),
      handIn(),
    ]);

    const popovers = wrapper.findAllComponents({
      name: "CatalogueItemPopover",
    });

    expect(popovers).toHaveLength(1);
    expect(popovers[0].props("item")).toMatchObject({
      type: "Commodity",
      slug: "quartz",
    });
    expect(wrapper.text()).toContain("14× Yormandi Eye");
  });

  it("falls back to the ref for an entry the files do not name", async () => {
    const wrapper = await mount([handIn({ name: null })]);

    expect(wrapper.text()).toContain("124da32f-de8f-45f6-a2f1-81fd47752b2d");
  });
});
