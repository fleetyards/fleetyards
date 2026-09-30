import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type HardpointStat } from "@/frontend/composables/useHardpointStats";
import Component from "./index.vue";

const router = () =>
  createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      {
        path: "/components/:slug",
        name: "component",
        component: { template: "<div />" },
      },
    ],
  });

const stats = (count: number, primary = 1): HardpointStat[] =>
  Array.from({ length: count }, (_, index) => ({
    label: `Stat ${index}`,
    value: String(index),
    primary: index < primary,
  }));

type Props = Omit<InstanceType<typeof Component>["$props"], "title">;

const mount = (props: Props) =>
  mountWithDefaults(Component, {
    props: { compact: true, ...props, title: "Glacier" },
    plugins: [router()],
  });

describe("StatsCard", () => {
  it("leads with one key figure even when two are marked key", async () => {
    const wrapper = await mount({ stats: stats(4, 2) });

    const tiles = wrapper.findAll(".metrics-card__tile");
    expect(tiles).toHaveLength(1);
    expect(tiles[0].text()).toContain("Stat 0");
    expect(wrapper.findAll(".metrics-card__row")).toHaveLength(3);
  });

  it("caps the rows and says how many more the detail page has", async () => {
    const wrapper = await mount({ stats: stats(15), maxStats: 10 });

    expect(wrapper.findAll(".metrics-card__row")).toHaveLength(10);
    expect(wrapper.find(".stats-card__note").text()).toContain("4");
  });

  it("says so when there is nothing to show", async () => {
    const wrapper = await mount({ stats: [], emptyText: "Nothing recorded." });

    expect(wrapper.find(".stats-card__note").text()).toBe("Nothing recorded.");
  });

  it("shows a loader instead of figures while loading", async () => {
    const wrapper = await mount({ stats: stats(3), loading: true });

    expect(wrapper.find(".metrics-card__row").exists()).toBe(false);
    expect(wrapper.find(".stats-card__loading").exists()).toBe(true);
  });

  it("links to the detail page and reports the navigation", async () => {
    const wrapper = await mount({
      stats: stats(2),
      to: { name: "component", params: { slug: "glacier" } },
    });

    const link = wrapper.find("[data-test='stats-card-link']");
    expect(link.attributes("href")).toBe("#/components/glacier");

    await link.trigger("click");
    expect(wrapper.emitted("navigate")).toHaveLength(1);
  });

  it("has no link without a destination", async () => {
    const wrapper = await mount({ stats: stats(2) });

    expect(wrapper.find("[data-test='stats-card-link']").exists()).toBe(false);
  });

  describe("on a detail page", () => {
    it("shows every key figure as a tile, accenting only the first", async () => {
      const wrapper = await mount({ stats: stats(4, 2), compact: false });

      const tiles = wrapper.findAll(".metrics-card__tile");
      expect(tiles).toHaveLength(2);
      expect(tiles[0].classes()).toContain("metrics-card__tile--primary");
      expect(tiles[1].classes()).not.toContain("metrics-card__tile--primary");
    });

    it("shows every other figure, uncapped, in the split list", async () => {
      const wrapper = await mount({ stats: stats(15), compact: false });

      expect(wrapper.findAll(".metrics-card__row")).toHaveLength(14);
      expect(wrapper.find(".metrics-card__rows--split").exists()).toBe(true);
      expect(wrapper.find(".stats-card__note").exists()).toBe(false);
    });

    it("links nowhere, since it is the page", async () => {
      const wrapper = await mount({
        stats: stats(2),
        compact: false,
        to: { name: "component", params: { slug: "glacier" } },
      });

      expect(wrapper.find("[data-test='stats-card-link']").exists()).toBe(
        false,
      );
    });
  });
});
