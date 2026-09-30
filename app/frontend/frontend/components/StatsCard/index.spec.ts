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
    props: { ...props, title: "Glacier" },
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
    expect(wrapper.find(".stats-card__more").text()).toContain("4");
  });

  it("says so when there is nothing to show", async () => {
    const wrapper = await mount({ stats: [] });

    expect(wrapper.find(".stats-card__empty").exists()).toBe(true);
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
});
