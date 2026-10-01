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

    const heroes = wrapper.findAll("[data-test='stats-card-hero']");
    expect(heroes).toHaveLength(1);
    expect(heroes[0].text()).toContain("Stat 0");
    expect(wrapper.findAll("[data-test='stats-card-row']")).toHaveLength(3);
  });

  it("caps the rows and says how many more the detail page has", async () => {
    const wrapper = await mount({ stats: stats(15), maxStats: 10 });

    expect(wrapper.findAll("[data-test='stats-card-row']")).toHaveLength(10);
    expect(wrapper.find(".stats-card__note").text()).toContain("4");
  });

  it("names its type and category above the title, with the type's icon", async () => {
    const wrapper = await mount({ kind: "Component", category: "Weapons" });

    expect(wrapper.find(".stats-card__eyebrow").text()).toBe(
      "Component · Weapons",
    );
    expect(wrapper.find(".stats-card__icon i").classes()).toContain(
      "fa-microchip",
    );
  });

  it("gives a long last spec the room the short ones leave", async () => {
    const wrapper = await mount({
      badges: [
        { key: "size", label: "Size", value: "2" },
        { key: "grade", label: "Grade", value: "A" },
        { key: "class", label: "Class", value: "Ballistic cannon" },
      ],
    });

    const strip = wrapper.find(".stats-card__specs");
    expect(strip.attributes("style")).toContain(
      "grid-template-columns: repeat(2, minmax(0, max-content)) minmax(0, 1fr)",
    );
    // The full value stays readable where the strip cuts it short.
    expect(
      wrapper.findAll(".stats-card__spec-value")[2].attributes("title"),
    ).toBe("Ballistic cannon");
  });

  it("sets prominent badges as equal tiles, with their unit", async () => {
    const wrapper = await mount({
      prominentBadges: true,
      badges: [
        { key: "buy", label: "Buy", value: "6,840", unit: "aUEC" },
        { key: "sell", label: "Sell", value: "7,200", unit: "aUEC" },
      ],
    });

    const strip = wrapper.find(".stats-card__specs");
    expect(strip.classes()).toContain("stats-card__specs--prominent");
    expect(strip.attributes("style")).toContain(
      "grid-template-columns: repeat(2, minmax(0, 1fr))",
    );
    expect(strip.text()).toContain("aUEC");
  });

  it("shows a status pill in its tone", async () => {
    const wrapper = await mount({
      status: { label: "Flight Ready", tone: "success" },
    });

    const status = wrapper.find("[data-test='stats-card-status']");
    expect(status.text()).toBe("Flight Ready");
    expect(status.classes()).toContain("stats-card__status--success");
  });

  it("says so when there is nothing to show", async () => {
    const wrapper = await mount({ stats: [], emptyText: "Nothing recorded." });

    expect(wrapper.find(".stats-card__note").text()).toBe("Nothing recorded.");
  });

  it("holds its shape with a still skeleton while loading, and says it is loading", async () => {
    const wrapper = await mount({ stats: stats(3), loading: true });

    expect(wrapper.find("[data-test='stats-card-row']").exists()).toBe(false);
    expect(wrapper.find("[data-test='stats-card-skeleton']").exists()).toBe(
      true,
    );
    expect(wrapper.find(".stats-card").attributes("aria-busy")).toBe("true");
    expect(wrapper.find(".loading-line").classes()).toContain(
      "loading-line--active",
    );
    expect(wrapper.find("[role='status']").text()).toContain("Glacier");
    // The name is known before the record arrives.
    expect(wrapper.find(".stats-card__title").text()).toBe("Glacier");
  });

  it("lays a status over the image when there is one", async () => {
    const wrapper = await mount({
      kind: "Model",
      image: "https://example.test/carrack.webp",
      status: { label: "Flight Ready", tone: "success" },
    });

    const status = wrapper.find("[data-test='stats-card-status']");
    expect(status.classes()).toContain("stats-card__status--over-image");
    expect(
      wrapper.find(".stats-card__media").element.contains(status.element),
    ).toBe(true);
    expect(wrapper.findAll("[data-test='stats-card-status']")).toHaveLength(1);
  });

  it("holds a ship's image space while it loads", async () => {
    const wrapper = await mount({ kind: "Model", loading: true });

    expect(wrapper.find(".stats-card__image-well").exists()).toBe(true);
  });

  it("announces the generic loading text when it has no name", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { compact: true, title: "", loading: true },
      plugins: [router()],
    });

    const status = wrapper.find("[role='status']").text();
    expect(status).not.toBe("");
    expect(status).not.toMatch(/\s…$/);
  });

  it("renders no empty body for a slot that carries nothing", async () => {
    const wrapper = await mount({
      badges: [{ key: "size", label: "Size", value: "2" }],
    });

    expect(wrapper.find(".stats-card__body").exists()).toBe(false);
  });

  it("links to the detail page and reports the navigation", async () => {
    const wrapper = await mount({
      stats: stats(2),
      kind: "Component",
      to: { name: "component", params: { slug: "glacier" } },
    });

    const link = wrapper.find("[data-test='stats-card-link']");
    expect(link.attributes("href")).toBe("#/components/glacier");
    expect(link.text()).toBe("Open component");

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
