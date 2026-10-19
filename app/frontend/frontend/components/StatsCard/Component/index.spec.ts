import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { HardpointCategoryEnum, type Component } from "@/services/fyApi";
import DuotoneGlyph from "@/shared/components/DuotoneGlyph/index.vue";
import { HARDPOINT_GLYPHS } from "@/frontend/components/Models/Hardpoints/CategoryIcon/glyphs";
import ComponentStatsCard from "./index.vue";

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

const drive = {
  id: "1",
  name: "Torrent",
  slug: "torrent",
  category: "quantumdrive",
  typeData: {
    driveSpeed: 263_400_000,
    splineJumpParams: { driveSpeed: 400_000, spoolUpTime: 6 },
  },
} as unknown as Component;

const mount = (compact: boolean) =>
  mountWithDefaults(ComponentStatsCard, {
    props: { component: drive, compact },
    plugins: [router()],
  });

describe("ComponentStatsCard", () => {
  it("keeps a drive's orbit-jump figures when floating over a list", async () => {
    const wrapper = await mount(true);

    expect(wrapper.text()).toContain("Orbit Spool Up");
  });

  it("leaves them to their own card on the detail page", async () => {
    const wrapper = await mount(false);

    expect(wrapper.text()).not.toContain("Orbit Spool Up");
  });

  it("draws its category's icon rather than the generic component one", async () => {
    const wrapper = await mount(true);

    expect(wrapper.findComponent(DuotoneGlyph).props("glyph")).toBe(
      HARDPOINT_GLYPHS[HardpointCategoryEnum.QUANTUMDRIVE],
    );
  });

  describe("integrity", () => {
    const shield = {
      id: "2",
      name: "Bulwark",
      slug: "bulwark",
      category: "shieldgenerator",
      typeData: { maxHealth: 1000 },
      durability: { health: 500 },
    } as unknown as Component;

    const rows = async (props: Record<string, unknown>) => {
      const wrapper = await mountWithDefaults(ComponentStatsCard, {
        props: { component: shield, compact: true, ...props },
        plugins: [router()],
      });

      return wrapper.findAll("[data-test='stats-card-row']");
    };

    it("shows a part's integrity when floating over a list", async () => {
      const integrity = (await rows({})).find((row) =>
        row.text().includes("Integrity"),
      );

      expect(integrity?.text()).toContain("500");
    });

    // A crafted part against the catalogue's: what crafting moved is marked.
    it("marks the figures crafting moved", async () => {
      const crafted = {
        ...shield,
        durability: { health: 600 },
      } as unknown as Component;

      const integrity = (
        await rows({ component: crafted, stock: shield })
      ).find((row) => row.text().includes("Integrity"));

      expect(integrity?.find(".stats-card__value--changed").exists()).toBe(
        true,
      );
    });
  });
});
